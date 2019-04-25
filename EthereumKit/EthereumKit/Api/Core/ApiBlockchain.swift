import RxSwift

class ApiBlockchain {
    private let refreshInterval: TimeInterval = 30
    private let ipfsRefreshInterval: TimeInterval = 60 * 3

    private var disposeBag = DisposeBag()

    weak var delegate: IBlockchainDelegate?

    private let storage: IApiStorage
    private let transactionsProvider: ITransactionsProvider
    private let rpcApiProvider: IRpcApiProvider
    private let reachabilityManager: IReachabilityManager
    private let transactionSigner: TransactionSigner
    private let transactionBuilder: TransactionBuilder
    private var logger: Logger?

    private var started = false

    private var syncing = false
    private var _syncState: EthereumKit.SyncState = .notSynced
    private(set) var syncState: EthereumKit.SyncState {
        get {
            return _syncState
        }
        set {
            if _syncState == .synced {
                return
            }

            if _syncState != newValue {
                _syncState = newValue
                delegate?.onUpdate(syncState: _syncState)
            }
        }
    }

    let address: Data

    init(storage: IApiStorage, transactionsProvider: ITransactionsProvider, rpcApiProvider: IRpcApiProvider, reachabilityManager: IReachabilityManager, transactionSigner: TransactionSigner, transactionBuilder: TransactionBuilder, address: Data, logger: Logger? = nil) {
        self.storage = storage
        self.transactionsProvider = transactionsProvider
        self.rpcApiProvider = rpcApiProvider
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
        guard started else {
            return
        }

        guard reachabilityManager.isReachable else {
            self.syncState = .notSynced
            return
        }
        guard !syncing else {
            return
        }

        self.syncing = true
        self.syncState = .syncing

        Single.zip(
                        rpcApiProvider.lastBlockHeightSingle(),
                        rpcApiProvider.balanceSingle(address: address)
                )
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onSuccess: { [weak self] lastBlockHeight, balance in
                    self?.update(lastBlockHeight: lastBlockHeight)
                    self?.update(balance: balance)

                    self?.refreshTransactions()
                }, onError: { [weak self] error in
                    self?.syncing = false
                    self?.syncState = .notSynced
                    self?.logger?.error("Sync Failed: lastBlockHeight and balance: \(error)")
                })
                .disposed(by: disposeBag)

    }

    private func refreshTransactions() {
        let lastTransactionBlockHeight = storage.lastTransactionBlockHeight() ?? 0

        transactionsProvider.transactionsSingle(address: address, startBlock: lastTransactionBlockHeight + 1)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onSuccess: { [weak self] transactions in
                    self?.update(transactions: transactions)
                    self?.syncing = false
                    self?.syncState = .synced
                }, onError: { [weak self] _ in
                    self?.syncing = false
                    self?.syncState = .notSynced
                })
                .disposed(by: disposeBag)
    }

    private func update(lastBlockHeight: Int) {
        storage.save(lastBlockHeight: lastBlockHeight)
        delegate?.onUpdate(lastBlockHeight: lastBlockHeight)
    }

    private func update(balance: BInt) {
        storage.save(balance: balance, address: address)
        delegate?.onUpdate(balance: balance)
    }

    private func update(transactions: [Transaction]) {
        storage.save(transactions: transactions)
        delegate?.onUpdate(transactions: transactions.filter {
            $0.input == Data()
        })
    }

    private func sendSingle(rawTransaction: RawTransaction, nonce: Int) throws -> Single<Transaction> {
        let signature = try transactionSigner.sign(rawTransaction: rawTransaction, nonce: nonce)
        let transaction = transactionBuilder.transaction(rawTransaction: rawTransaction, nonce: nonce, signature: signature, address: address)
        let encoded = transactionBuilder.encode(rawTransaction: rawTransaction, signature: signature, nonce: nonce)

        return rpcApiProvider.sendSingle(signedTransaction: encoded)
                .map {
                    transaction
                }
    }

    private func pullTransactionTimestamps(ethereumLogs: [EthereumLog]) -> Single<[EthereumLog]> {
        var logsByBlockNumber = [Int: [EthereumLog]]()

        for log in ethereumLogs {
            if var logs = logsByBlockNumber[log.blockNumber] {
                logs.append(log)
            } else {
                logsByBlockNumber[log.blockNumber] = [log]
            }
        }

        var requestSingles = [Single<Block>]()
        for (blockNumber, _) in logsByBlockNumber {
            requestSingles.append(rpcApiProvider.getBlock(byNumber: blockNumber))
        }

        return Single.zip(requestSingles)
                .map { (blocks: [Block]) in
                    var resultLogs = [EthereumLog]()

                    for block in blocks {
                        guard let logsOfBlock = logsByBlockNumber[block.number] else {
                            continue
                        }

                        for log in logsOfBlock {
                            log.timestamp = Double(block.timestamp)
                            resultLogs.append(log)
                        }
                    }

                    return resultLogs
                }
    }

}

extension ApiBlockchain: IBlockchain {

    func start() {
        started = true

        refreshAll()
    }

    func stop() {
        started = false
    }

    func clear() {
        storage.clear()
    }

    var lastBlockHeight: Int? {
        return storage.lastBlockHeight
    }

    var balance: BInt? {
        return storage.balance(forAddress: address)
    }

    func transactionsSingle(fromHash: Data?, limit: Int?) -> Single<[Transaction]> {
        return storage.transactionsSingle(fromHash: fromHash, limit: limit, contractAddress: nil)
    }

    func sendSingle(rawTransaction: RawTransaction) -> Single<Transaction> {
        return rpcApiProvider.transactionCountSingle(address: address)
                .flatMap { [unowned self] nonce -> Single<Transaction> in
                    return try self.sendSingle(rawTransaction: rawTransaction, nonce: nonce)
                }
                .do(onSuccess: { [weak self] transaction in
                    self?.update(transactions: [transaction])
                    self?.refreshAll()
                })
    }

    func getLogsSingle(address: Data?, topics: [Any], fromBlock: Int, toBlock: Int, pullTimestamps: Bool) -> Single<[EthereumLog]> {
        return rpcApiProvider.getLogs(address: address, fromBlock: fromBlock, toBlock: toBlock, topics: topics)
                .flatMap { [unowned self] logs in
                    if pullTimestamps {
                        return self.pullTransactionTimestamps(ethereumLogs: logs)
                    } else {
                        return Single.just(logs)
                    }
                }
    }

    func getStorageAt(contractAddress: Data, positionData: Data, blockHeight: Int) -> Single<Data> {
        return rpcApiProvider.getStorageAt(contractAddress: contractAddress.toHexString(), position: positionData.toHexString(), blockNumber: blockHeight)
                .flatMap { value -> Single<Data> in
                    guard let data = Data(hex: value) else {
                        return Single.error(EthereumKit.ApiError.invalidData)
                    }

                    return Single.just(data)
                }
    }

    func call(contractAddress: Data, data: Data, blockHeight: Int?) -> Single<Data> {
        return rpcApiProvider.call(contractAddress: contractAddress.toHexString(), data: data.toHexString(), blockNumber: blockHeight)
                .flatMap { value -> Single<Data> in
                    guard let data = Data(hex: value) else {
                        return Single.error(EthereumKit.ApiError.invalidData)
                    }

                    return Single.just(data)
                }
    }

}

extension ApiBlockchain {

    static func instance(storage: IApiStorage, transactionSigner: TransactionSigner, transactionBuilder: TransactionBuilder, address: Data, rpcApiProvider: IRpcApiProvider, transactionsProvider: ITransactionsProvider, logger: Logger? = nil) -> ApiBlockchain {
        let reachabilityManager: IReachabilityManager = ReachabilityManager()

        return ApiBlockchain(storage: storage, transactionsProvider: transactionsProvider, rpcApiProvider: rpcApiProvider, reachabilityManager: reachabilityManager, transactionSigner: transactionSigner, transactionBuilder: transactionBuilder, address: address, logger: logger)
    }

}
