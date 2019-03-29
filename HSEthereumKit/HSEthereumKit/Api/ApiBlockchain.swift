import RxSwift

class ApiBlockchain {
    private let refreshInterval: TimeInterval = 30
    private let ipfsRefreshInterval: TimeInterval = 60 * 3

    private var disposeBag = DisposeBag()

    weak var delegate: IBlockchainDelegate?

    private let storage: IApiStorage
    private let apiProvider: IApiProvider
    private let reachabilityManager: IReachabilityManager
    private let transactionSigner: TransactionSigner
    private let transactionBuilder: TransactionBuilder
    private var logger: Logger?

    private var erc20Contracts = [Data: Erc20Contract]()
    private(set) var syncState: EthereumKit.SyncState = .notSynced {
        didSet {
            if oldValue != syncState {
                delegate?.onUpdate(syncState: syncState)
            }
        }
    }

    let address: Data

    init(storage: IApiStorage, apiProvider: IApiProvider, reachabilityManager: IReachabilityManager, transactionSigner: TransactionSigner, transactionBuilder: TransactionBuilder, address: Data, logger: Logger? = nil) {
        self.storage = storage
        self.apiProvider = apiProvider
        self.reachabilityManager = reachabilityManager
        self.transactionSigner = transactionSigner
        self.transactionBuilder = transactionBuilder
        self.address = address
        self.logger = logger

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
                }, onError: { [weak self] error in
                    self?.changeAllSyncStates(syncState: .notSynced)
                    self?.logger?.error("Sync Failed: lastBlockHeight and balance: \(error)")
                })
                .disposed(by: disposeBag)

    }

    private func refreshTransactions() {
        let lastTransactionBlockHeight = storage.lastTransactionBlockHeight(erc20: false) ?? 0

        apiProvider.transactionsSingle(address: address, startBlock: lastTransactionBlockHeight + 1)
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

        apiProvider.transactionsErc20Single(address: address, startBlock: erc20LastTransactionBlockHeight + 1)
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

    private func update(syncState: EthereumKit.SyncState, contractAddress: Data) {
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

    private func update(balance: BInt) {
        storage.save(balance: balance, address: address)
        delegate?.onUpdate(balance: balance)
    }

    private func updateErc20(balance: BInt, contractAddress: Data) {
        storage.save(balance: balance, address: contractAddress)
        delegate?.onUpdateErc20(balance: balance, contractAddress: contractAddress)
    }

    private func update(transactions: [Transaction]) {
        storage.save(transactions: transactions)

        // transactions related to erc20 should be saved to db, but not reported to delegate
        delegate?.onUpdate(transactions: transactions.filter { $0.input == Data() })
    }

    private func updateErc20(transactions: [Transaction]) {
        storage.save(transactions: transactions)

//        var contractTransactions = [String: [EthereumTransaction]]()

//        transactions.forEach { transaction in
//            if let contractAddress = transaction.contractAddress {
//                if contractTransactions[contractAddress] == nil {
//                    contractTransactions[contractAddress] = []
//                }
//                contractTransactions[contractAddress]?.append(transaction)
//            }
//        }

//        for (contractAddress, transactions) in contractTransactions {
//            if erc20Contracts[contractAddress] != nil {
//                delegate?.onUpdateErc20(transactions: transactions, contractAddress: contractAddress)
//            }
//        }
    }

    private func sendSingle(rawTransaction: RawTransaction, nonce: Int) throws -> Single<Transaction> {
        let signature = try transactionSigner.sign(rawTransaction: rawTransaction, nonce: nonce)
        let transaction = transactionBuilder.transaction(rawTransaction: rawTransaction, nonce: nonce, signature: signature, address: address)
        let encoded = transactionBuilder.encode(rawTransaction: rawTransaction, signature: signature, nonce: nonce)

        return apiProvider.sendSingle(signedTransaction: encoded)
                .map {
                    transaction
                }
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

    func syncStateErc20(contractAddress: Data) -> EthereumKit.SyncState {
        return erc20Contracts[contractAddress]?.syncState ?? .notSynced
    }

    var lastBlockHeight: Int? {
        return storage.lastBlockHeight
    }

    var balance: BInt? {
        return storage.balance(forAddress: address)
    }

    func balanceErc20(contractAddress: Data) -> BInt? {
        return storage.balance(forAddress: contractAddress)
    }

    func transactionsSingle(fromHash: Data?, limit: Int?) -> Single<[Transaction]> {
        return storage.transactionsSingle(fromHash: fromHash, limit: limit, contractAddress: nil)
    }

    func transactionsErc20Single(contractAddress: Data, fromHash: Data?, limit: Int?) -> Single<[Transaction]> {
        return storage.transactionsSingle(fromHash: fromHash, limit: limit, contractAddress: contractAddress)
    }

    func sendSingle(rawTransaction: RawTransaction) -> Single<Transaction> {
        return apiProvider.transactionCountSingle(address: address)
                .flatMap { [unowned self] nonce -> Single<Transaction> in
                    return try self.sendSingle(rawTransaction: rawTransaction, nonce: nonce)
                }
                .do(onSuccess: { [weak self] transaction in
                    self?.update(transactions: [transaction])
                })
    }

    func register(contractAddress: Data) {
        guard erc20Contracts[contractAddress] == nil else {
            return
        }

        erc20Contracts[contractAddress] = Erc20Contract(address: contractAddress, syncState: .notSynced)

        refreshAll()
    }

    func unregister(contractAddress: Data) {
        erc20Contracts.removeValue(forKey: contractAddress)
    }

}

extension ApiBlockchain {

    struct Erc20Contract: Equatable {
        let address: Data
        var syncState: EthereumKit.SyncState
    }

    enum ApiError: Error {
        case contractNotRegistered
        case internalError
    }

}

extension ApiBlockchain {

    static func instance(storage: IApiStorage, network: INetwork, transactionSigner: TransactionSigner, transactionBuilder: TransactionBuilder, address: Data, infuraProjectId: String, etherscanApiKey: String, logger: Logger? = nil) -> ApiBlockchain {
        let networkManager = NetworkManager(logger: logger)
        let apiProvider: IApiProvider = ApiProvider(networkManager: networkManager, network: network, infuraProjectId: infuraProjectId, etherscanApiKey: etherscanApiKey)
        let reachabilityManager: IReachabilityManager = ReachabilityManager()

        return ApiBlockchain(storage: storage, apiProvider: apiProvider, reachabilityManager: reachabilityManager, transactionSigner: transactionSigner, transactionBuilder: transactionBuilder, address: address, logger: logger)
    }

}
