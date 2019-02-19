import RxSwift
import HSHDWalletKit

class ApiBlockchain {
    private var disposeBag = DisposeBag()

    weak var delegate: IBlockchainDelegate?

    private let storage: IStorage
    private let apiProvider: IApiProvider

    private var erc20Contracts = [Erc20Contract]()

    let ethereumAddress: String
    private(set) var gasPrice: Decimal = 10_000_000_000 / pow(10, 18)
    let gasLimitEthereum = 21_000
    let gasLimitErc20 = 100_000

    init(storage: IStorage, apiProvider: IApiProvider, ethereumAddress: String) {
        self.storage = storage
        self.apiProvider = apiProvider
        self.ethereumAddress = ethereumAddress

        if let storedGasPrice = storage.gasPrice {
            gasPrice = storedGasPrice
        }
    }

    private func refreshAll() {
        changeAllStates(state: .syncing)

        Single.zip(
                        apiProvider.getLastBlockHeight(),
                        apiProvider.getGasPrice(),
                        apiProvider.getBalance(address: ethereumAddress)
                )
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] lastBlockHeight, gasPrice, balance in
                    self?.update(lastBlockHeight: lastBlockHeight)
                    self?.update(gasPrice: gasPrice)
                    self?.update(balance: balance)

                    self?.refreshTransactions()
                }, onError: { [weak self] _ in
                    self?.changeAllStates(state: .notSynced)
                })
                .disposed(by: disposeBag)

    }

    private func refreshTransactions() {
        let lastTransactionBlockHeight = storage.lastTransactionBlockHeight(erc20: false) ?? 0

        apiProvider.getTransactions(address: ethereumAddress, startBlock: Int64(lastTransactionBlockHeight + 1))
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] transactions in
                    self?.update(transactions: transactions)
                    self?.delegate?.onUpdate(syncState: .synced)
                }, onError: { [weak self] _ in
                    self?.delegate?.onUpdate(syncState: .notSynced)
                })
                .disposed(by: disposeBag)

        guard !erc20Contracts.isEmpty else {
            return
        }

        let erc20LastTransactionBlockHeight = storage.lastTransactionBlockHeight(erc20: true) ?? 0

        apiProvider.getTransactionsErc20(address: ethereumAddress, startBlock: Int64(erc20LastTransactionBlockHeight + 1), contracts: erc20Contracts)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] transactions in
                    self?.updateErc20(transactions: transactions)
                    self?.refreshErc20Balances()
                }, onError: { [weak self] _ in
                    self?.erc20Contracts.forEach {
                        self?.delegate?.onUpdateErc20(syncState: .notSynced, contractAddress: $0.address)
                    }
                })
                .disposed(by: disposeBag)
    }

    private func refreshErc20Balances() {
        erc20Contracts.forEach { contract in
            apiProvider.getBalanceErc20(address: ethereumAddress, contractAddress: contract.address, decimal: contract.decimal)
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                    .observeOn(MainScheduler.instance)
                    .subscribe(onSuccess: { [weak self] balance in
                        self?.updateErc20(balance: balance, contractAddress: contract.address)
                        self?.delegate?.onUpdateErc20(syncState: .synced, contractAddress: contract.address)
                    }, onError: { [weak self] _ in
                        self?.delegate?.onUpdateErc20(syncState: .notSynced, contractAddress: contract.address)
                    })
                    .disposed(by: disposeBag)
        }
    }

    private func changeAllStates(state: EthereumKit.SyncState) {
        delegate?.onUpdate(syncState: state)
        erc20Contracts.forEach {
            delegate?.onUpdateErc20(syncState: state, contractAddress: $0.address)
        }
    }

    private func update(lastBlockHeight: Int) {
        storage.save(lastBlockHeight: lastBlockHeight)
        delegate?.onUpdate(lastBlockHeight: lastBlockHeight)
    }

    private func update(gasPrice: Decimal) {
        self.gasPrice = gasPrice
        storage.save(gasPrice: gasPrice)
    }

    private func update(balance: Decimal) {
        storage.save(balance: balance, address: ethereumAddress)
        delegate?.onUpdate(balance: balance)
    }

    private func updateErc20(balance: Decimal, contractAddress: String) {
        storage.save(balance: balance, address: contractAddress)
        delegate?.onUpdateErc20(balance: balance, contractAddress: contractAddress)
    }

    private func update(transactions: [EthereumTransaction]) {
        storage.save(transactions: transactions)
        delegate?.onUpdate(transactions: transactions)
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
            delegate?.onUpdateErc20(transactions: transactions, contractAddress: contractAddress)
        }
    }

    private func sendSingle(to address: String, nonce: Int, amount: Decimal, gasPrice: Decimal?) -> Single<EthereumTransaction> {
        return apiProvider.send(from: ethereumAddress, to: address, nonce: nonce, amount: amount, gasPrice: gasPrice ?? self.gasPrice, gasLimit: gasLimitEthereum)
    }

    private func sendErc20Single(to address: String, contractAddress: String, nonce: Int, amount: Decimal, gasPrice: Decimal?) -> Single<EthereumTransaction> {
        guard let erc20Contract = erc20Contracts.first(where: { $0.address == contractAddress }) else {
            return Single.error(ApiError.contractNotRegistered)
        }

        return apiProvider.sendErc20(contractAddress: erc20Contract.address, decimal: erc20Contract.decimal, from: ethereumAddress, to: address, nonce: nonce, amount: amount, gasPrice: gasPrice ?? self.gasPrice, gasLimit: gasLimitErc20)
    }

}

extension ApiBlockchain: IBlockchain {

    func start() {
        // todo: check reachability and decide if reachability should be in this layer

        refreshAll()
    }

    func stop() {
        disposeBag = DisposeBag()
    }

    func clear() {
        erc20Contracts = []
        disposeBag = DisposeBag()
    }

    func register(contractAddress: String, decimal: Int) {
        guard !erc20Contracts.contains(where: { $0.address == contractAddress }) else {
            return
        }

        erc20Contracts.append(Erc20Contract(address: contractAddress, decimal: decimal))

        // todo: refresh if not already refreshing

    }

    func unregister(contractAddress: String) {
        if let index = erc20Contracts.firstIndex(where: { $0.address == contractAddress }) {
            erc20Contracts.remove(at: index)
        }
    }

    func sendSingle(to address: String, amount: Decimal, gasPrice: Decimal?) -> Single<EthereumTransaction> {
        return apiProvider.getTransactionCount(address: ethereumAddress)
                .flatMap { [weak self] nonce -> Single<EthereumTransaction> in
                    guard let weakSelf = self else {
                        return Single.error(ApiError.internalError)
                    }

                    return weakSelf.sendSingle(to: address, nonce: nonce, amount: amount, gasPrice: gasPrice)
                }
                .do(onSuccess: { [weak self] transaction in
                    self?.storage.save(transactions: [transaction])
                })
    }

    func sendErc20Single(to address: String, contractAddress: String, amount: Decimal, gasPrice: Decimal?) -> Single<EthereumTransaction> {
        return apiProvider.getTransactionCount(address: ethereumAddress)
                .flatMap { [weak self] nonce -> Single<EthereumTransaction> in
                    guard let weakSelf = self else {
                        return Single.error(ApiError.internalError)
                    }

                    return weakSelf.sendErc20Single(to: address, contractAddress: contractAddress, nonce: nonce, amount: amount, gasPrice: gasPrice)
                }
                .do(onSuccess: { [weak self] transaction in
                    self?.storage.save(transactions: [transaction])
                })
    }

}

extension ApiBlockchain {

    struct Erc20Contract: Equatable {
        let address: String
        let decimal: Int
    }

    enum ApiError: Error {
        case contractNotRegistered
        case internalError
    }

}

extension ApiBlockchain {

    static func apiBlockchain(storage: IStorage, words: [String], testMode: Bool, infuraKey: String, etherscanKey: String, debugPrints: Bool = false) throws -> ApiBlockchain {
        let network: Network = testMode ? .ropsten : .mainnet

        let hdWallet = try Wallet(seed: Mnemonic.seed(mnemonic: words), network: network, debugPrints: debugPrints)

        let configuration = Configuration(
                network: network,
                nodeEndpoint: network.infura + infuraKey,
                etherscanAPIKey: etherscanKey,
                debugPrints: debugPrints
        )
        let apiProvider = GethProvider(geth: Geth(configuration: configuration), hdWallet: hdWallet)

        return ApiBlockchain(storage: storage, apiProvider: apiProvider, ethereumAddress: hdWallet.address())
    }

}