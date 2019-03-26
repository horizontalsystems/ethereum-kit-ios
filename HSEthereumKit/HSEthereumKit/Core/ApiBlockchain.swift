import RxSwift
import HSHDWalletKit

class ApiBlockchain {
    private let refreshInterval: TimeInterval = 30
    private let ipfsRefreshInterval: TimeInterval = 60 * 3

    private var disposeBag = DisposeBag()

    weak var delegate: IBlockchainDelegate?

    private let storage: IApiStorage
    private let apiProvider: IApiProvider
    private let reachabilityManager: IReachabilityManager

    private var erc20Contracts = [String: Erc20Contract]()
    private(set) var syncState: EthereumKit.SyncState = .notSynced {
        didSet {
            if oldValue != syncState {
                delegate?.onUpdate(syncState: syncState)
            }
        }
    }

    let address: String

    init(storage: IApiStorage, apiProvider: IApiProvider, reachabilityManager: IReachabilityManager, ethereumAddress: String) {
        self.storage = storage
        self.apiProvider = apiProvider
        self.reachabilityManager = reachabilityManager
        self.address = ethereumAddress

        Observable<Int>.interval(refreshInterval, scheduler: ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onNext: { [weak self] _ in
                    self?.refreshAll()
                })
                .disposed(by: disposeBag)

        reachabilityManager.reachabilitySignal
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onNext: { [weak self] in
                    self?.refreshAll()
                })
                .disposed(by: disposeBag)
    }

    private func refreshAll() {
        guard reachabilityManager.isReachable else {
            changeAllSyncStates(syncState: .notSynced)
            return
        }
        guard syncState != .syncing else {
            return
        }
        for contract in erc20Contracts.values {
            if contract.syncState == .syncing {
                return
            }
        }

        changeAllSyncStates(syncState: .syncing)

        Single.zip(
                        apiProvider.lastBlockHeightSingle(),
                        apiProvider.balanceSingle(address: address)
                )
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onSuccess: { [weak self] lastBlockHeight, balance in
                    self?.update(lastBlockHeight: lastBlockHeight)
                    self?.update(balance: balance)

                    self?.refreshTransactions()
                }, onError: { [weak self] _ in
                    self?.changeAllSyncStates(syncState: .notSynced)
                })
                .disposed(by: disposeBag)

    }

    private func refreshTransactions() {
        let lastTransactionBlockHeight = storage.lastTransactionBlockHeight(erc20: false) ?? 0

        apiProvider.transactionsSingle(address: address, startBlock: Int64(lastTransactionBlockHeight + 1))
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onSuccess: { [weak self] transactions in
                    self?.update(transactions: transactions)
                    self?.syncState = .synced
                }, onError: { [weak self] _ in
                    self?.syncState = .notSynced
                })
                .disposed(by: disposeBag)

        guard !erc20Contracts.isEmpty else {
            return
        }

        let erc20LastTransactionBlockHeight = storage.lastTransactionBlockHeight(erc20: true) ?? 0

        apiProvider.transactionsErc20Single(address: address, startBlock: Int64(erc20LastTransactionBlockHeight + 1))
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onSuccess: { [weak self] transactions in
                    self?.updateErc20(transactions: transactions)
                    self?.refreshErc20Balances()
                }, onError: { [weak self] _ in
                    self?.erc20Contracts.keys.forEach {
                        self?.update(syncState: .notSynced, contractAddress: $0)
                    }
                })
                .disposed(by: disposeBag)
    }

    private func refreshErc20Balances() {
        erc20Contracts.values.forEach { contract in
            apiProvider.balanceErc20Single(address: address, contractAddress: contract.address)
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                    .subscribe(onSuccess: { [weak self] balance in
                        self?.updateErc20(balance: balance, contractAddress: contract.address)
                        self?.update(syncState: .synced, contractAddress: contract.address)
                    }, onError: { [weak self] _ in
                        self?.update(syncState: .notSynced, contractAddress: contract.address)
                    })
                    .disposed(by: disposeBag)
        }
    }

    private func changeAllSyncStates(syncState: EthereumKit.SyncState) {
        self.syncState = syncState
        erc20Contracts.keys.forEach {
            update(syncState: syncState, contractAddress: $0)
        }
    }

    private func update(syncState: EthereumKit.SyncState, contractAddress: String) {
        guard erc20Contracts[contractAddress]?.syncState != syncState else {
            return
        }

        erc20Contracts[contractAddress]?.syncState = syncState
        delegate?.onUpdateErc20(syncState: syncState, contractAddress: contractAddress)
    }

    private func update(lastBlockHeight: Int) {
        storage.save(lastBlockHeight: lastBlockHeight)
        delegate?.onUpdate(lastBlockHeight: lastBlockHeight)
    }

    private func update(balance: String) {
        storage.save(balance: balance, address: address)
        delegate?.onUpdate(balance: balance)
    }

    private func updateErc20(balance: String, contractAddress: String) {
        storage.save(balance: balance, address: contractAddress)
        delegate?.onUpdateErc20(balance: balance, contractAddress: contractAddress)
    }

    private func update(transactions: [EthereumTransaction]) {
        storage.save(transactions: transactions)

        // transactions related to erc20 should be saved to db, but not reported to delegate
        delegate?.onUpdate(transactions: transactions.filter { $0.input == "0x" })
    }

    private func updateErc20(transactions: [EthereumTransaction]) {
        storage.save(transactions: transactions)

        var contractTransactions = [String: [EthereumTransaction]]()

        transactions.forEach { transaction in
            if let contractAddress = transaction.contractAddress {
                if contractTransactions[contractAddress] == nil {
                    contractTransactions[contractAddress] = []
                }
                contractTransactions[contractAddress]?.append(transaction)
            }
        }

        for (contractAddress, transactions) in contractTransactions {
            if erc20Contracts[contractAddress] != nil {
                delegate?.onUpdateErc20(transactions: transactions, contractAddress: contractAddress)
            }
        }
    }

    private func sendSingle(to toAddress: String, nonce: Int, amount: String, gasPrice: Int, gasLimit: Int) -> Single<EthereumTransaction> {
        return apiProvider.sendSingle(
                from: address,
                to: toAddress,
                nonce: nonce,
                amount: amount,
                gasPriceInWei: gasPrice,
                gasLimit: gasLimit
        )
    }

    private func sendErc20Single(contractAddress: String, to toAddress: String, nonce: Int, amount: String, gasPrice: Int, gasLimit: Int) -> Single<EthereumTransaction> {
        guard let erc20Contract = erc20Contracts[contractAddress] else {
            return Single.error(ApiError.contractNotRegistered)
        }

        return apiProvider.sendErc20Single(
                contractAddress: erc20Contract.address,
                from: address,
                to: toAddress,
                nonce: nonce,
                amount: amount,
                gasPriceInWei: gasPrice,
                gasLimit: gasLimit
        )
    }

}

extension ApiBlockchain: IBlockchain {

    func start() {
        refreshAll()
    }

    func clear() {
        erc20Contracts = [:]
        storage.clear()
    }

    func syncStateErc20(contractAddress: String) -> EthereumKit.SyncState {
        return erc20Contracts[contractAddress]?.syncState ?? .notSynced
    }

    var lastBlockHeight: Int? {
        return storage.lastBlockHeight
    }

    var balance: String? {
        return storage.balance(forAddress: address)
    }

    func balanceErc20(contractAddress: String) -> String? {
        return storage.balance(forAddress: contractAddress)
    }

    func transactionsSingle(fromHash: String?, limit: Int?) -> Single<[EthereumTransaction]> {
        return storage.transactionsSingle(fromHash: fromHash, limit: limit, contractAddress: nil)
    }

    func transactionsErc20Single(contractAddress: String, fromHash: String?, limit: Int?) -> Single<[EthereumTransaction]> {
        return storage.transactionsSingle(fromHash: fromHash, limit: limit, contractAddress: contractAddress)
    }

    func sendSingle(to toAddress: String, amount: String, gasPrice: Int, gasLimit: Int) -> Single<EthereumTransaction> {
        return apiProvider.transactionCountSingle(address: address)
                .flatMap { [weak self] nonce -> Single<EthereumTransaction> in
                    guard let weakSelf = self else {
                        return Single.error(ApiError.internalError)
                    }

                    return weakSelf.sendSingle(to: toAddress, nonce: nonce, amount: amount, gasPrice: gasPrice, gasLimit: gasLimit)
                }
                .do(onSuccess: { [weak self] transaction in
                    self?.update(transactions: [transaction])
                })
    }

    func sendErc20Single(contractAddress: String, to toAddress: String, amount: String, gasPrice: Int, gasLimit: Int) -> Single<EthereumTransaction> {
        return apiProvider.transactionCountSingle(address: address)
                .flatMap { [weak self] nonce -> Single<EthereumTransaction> in
                    guard let weakSelf = self else {
                        return Single.error(ApiError.internalError)
                    }

                    return weakSelf.sendErc20Single(contractAddress: contractAddress, to: toAddress, nonce: nonce, amount: amount, gasPrice: gasPrice, gasLimit: gasLimit)
                }
                .do(onSuccess: { [weak self] transaction in
                    self?.updateErc20(transactions: [transaction])
                })
    }

    func register(contractAddress: String) {
        guard erc20Contracts[contractAddress] == nil else {
            return
        }

        erc20Contracts[contractAddress] = Erc20Contract(address: contractAddress, syncState: .notSynced)

        refreshAll()
    }

    func unregister(contractAddress: String) {
        erc20Contracts.removeValue(forKey: contractAddress)
    }

}

extension ApiBlockchain {

    struct Erc20Contract: Equatable {
        let address: String
        var syncState: EthereumKit.SyncState
    }

    enum ApiError: Error {
        case contractNotRegistered
        case internalError
    }

}

extension ApiBlockchain {

    static func apiBlockchain(storage: IApiStorage, words: [String], testMode: Bool, infuraKey: String, etherscanKey: String, debugPrints: Bool = false) throws -> ApiBlockchain {
        let network: Network = testMode ? .ropsten : .mainnet

        let hdWallet = try Wallet(seed: Mnemonic.seed(mnemonic: words), network: network, debugPrints: debugPrints)

        let configuration = Configuration(
                network: network,
                nodeEndpoint: network.infura + infuraKey,
                etherscanAPIKey: etherscanKey,
                debugPrints: debugPrints
        )
        let apiProvider = GethProvider(geth: Geth(configuration: configuration), hdWallet: hdWallet)
        let reachabilityManager = ReachabilityManager()

        return ApiBlockchain(storage: storage, apiProvider: apiProvider, reachabilityManager: reachabilityManager, ethereumAddress: hdWallet.address())
    }

}
