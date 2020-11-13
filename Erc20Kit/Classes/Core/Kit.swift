import RxSwift
import EthereumKit
import BigInt

public class Kit {
    private let disposeBag = DisposeBag()

    private let contractAddress: Address
    private let ethereumKit: EthereumKit.Kit
    private let transactionManager: ITransactionManager
    private let balanceManager: IBalanceManager
    private let allowanceManager: AllowanceManager

    private let state: KitState

    init(contractAddress: Address, ethereumKit: EthereumKit.Kit, transactionManager: ITransactionManager, balanceManager: IBalanceManager, allowanceManager: AllowanceManager, state: KitState = KitState()) {
        self.contractAddress = contractAddress
        self.ethereumKit = ethereumKit
        self.transactionManager = transactionManager
        self.balanceManager = balanceManager
        self.allowanceManager = allowanceManager
        self.state = state

        onUpdateSyncState(syncState: ethereumKit.syncState)
        state.balance = balanceManager.balance

        ethereumKit.syncStateObservable
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] in
                    self?.onUpdateSyncState(syncState: $0)
                })
                .disposed(by: disposeBag)

        ethereumKit.lastBlockBloomFilterObservable
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] in
                    self?.onUpdateLastBlock(bloomFilter: $0)
                })
                .disposed(by: disposeBag)
    }

    private func onUpdateLastBlock(bloomFilter: BloomFilter) {
        if bloomFilter.mayContain(contractAddress: contractAddress) {
            balanceManager.sync()
        }
    }

    private func onUpdateSyncState(syncState: EthereumKit.SyncState) {
        switch syncState {
        case .synced:
            state.syncState = .syncing
            balanceManager.sync()
            transactionManager.immediateSync()
        case .syncing:
            state.syncState = .syncing
        case .notSynced(let error):
            state.syncState = .notSynced(error: error)
        }
    }

}

extension Kit {

    public func refresh() {
//        state.transactionsSyncState = .syncing
//        transactionManager.sync()
    }

    public var syncState: SyncState {
        state.syncState
    }

    public var transactionsSyncState: SyncState {
        state.transactionsSyncState
    }

    public var balance: BigUInt? {
        state.balance
    }

    public func sendSingle(to: Address, value: BigUInt, gasPrice: Int, gasLimit: Int) throws -> Single<Transaction> {
        transactionManager.sendSingle(to: to, value: value, gasPrice: gasPrice, gasLimit: gasLimit)
                .do(onSuccess: { [weak self] transaction in
                    self?.state.transactionsSubject.onNext([transaction])
                })
    }

    public func transactionsSingle(from: (hash: Data, interTransactionIndex: Int)?, limit: Int?) throws -> Single<[Transaction]> {
        transactionManager.transactionsSingle(from: from, limit: limit)
    }

    public func pendingTransactions() -> [Transaction] {
        transactionManager.pendingTransactions()
    }

    public func transaction(hash: Data, interTransactionIndex: Int) -> Transaction? {
        transactionManager.transaction(hash: hash, interTransactionIndex: interTransactionIndex)
    }

    public var syncStateObservable: Observable<SyncState> {
        state.syncStateSubject.asObservable()
    }

    public var transactionsSyncStateObservable: Observable<SyncState> {
        state.transactionsSyncStateSubject.asObservable()
    }

    public var balanceObservable: Observable<BigUInt> {
        state.balanceSubject.asObservable()
    }

    public var transactionsObservable: Observable<[Transaction]> {
        state.transactionsSubject.asObservable()
    }

    public func estimateGas(to: Address?, contractAddress: Address, value: BigUInt, gasPrice: Int?) -> Single<Int> {
        // without address - provide default gas limit
        guard let to = to else {
            return Single.just(EthereumKit.Kit.defaultGasLimit)
        }

        let data = transactionManager.transactionContractData(to: to, value: value)
        return ethereumKit.estimateGas(to: contractAddress, amount: nil, gasPrice: gasPrice, data: data)
    }

    public func allowanceSingle(spenderAddress: Address, defaultBlockParameter: DefaultBlockParameter = .latest) -> Single<String> {
        allowanceManager.allowanceSingle(spenderAddress: spenderAddress, defaultBlockParameter: defaultBlockParameter)
                .map { amount in
                    amount.description
                }
    }

    public func approveTransactionData(spenderAddress: Address, amount: BigUInt) -> TransactionData {
        allowanceManager.approveTransactionData(spenderAddress: spenderAddress, amount: amount)
    }

    public func approveSingle(spenderAddress: Address, amount: BigUInt, gasLimit: Int, gasPrice: Int) -> Single<Transaction> {
        allowanceManager.approveSingle(spenderAddress: spenderAddress, amount: amount, gasLimit: gasLimit, gasPrice: gasPrice)
                .do(onSuccess: { [weak self] tx in
                    self?.state.transactionsSubject.onNext([tx])
                })
    }

}

extension Kit: ITransactionManagerDelegate {

    func onSyncStarted() {
        state.transactionsSyncState = .syncing
    }

    func onSyncSuccess(transactions: [Transaction]) {
        if !transactions.isEmpty {
            state.transactionsSubject.onNext(transactions)
        }

        state.transactionsSyncState = .synced
    }

    func onSyncTransactionsFailed(error: Error) {
        state.transactionsSyncState = .notSynced(error: error)
    }

}

extension Kit: IBalanceManagerDelegate {

    func onSyncBalanceSuccess(balance: BigUInt) {
        if state.balance == balance {
            if case .synced = state.syncState {
                transactionManager.delayedSync(expectTransaction: false)
            }
        } else {
            transactionManager.delayedSync(expectTransaction: true)
        }

        state.syncState = .synced
        state.balance = balance
    }

    func onSyncBalanceFailed(error: Error) {
        state.syncState = .notSynced(error: error)
    }

}

extension Kit {

    public static func instance(ethereumKit: EthereumKit.Kit, contractAddress: Address) throws -> Kit {
        let databaseFileName = "\(ethereumKit.uniqueId)-\(contractAddress)"

        let address = ethereumKit.address

        let storage: ITransactionStorage & ITokenBalanceStorage = try GrdbStorage(databaseDirectoryUrl: databaseDirectoryUrl(), databaseFileName: databaseFileName)

        let dataProvider: IDataProvider = DataProvider(ethereumKit: ethereumKit)
        let transactionBuilder: ITransactionBuilder = TransactionBuilder()
//        let transactionProvider: ITransactionProvider = TransactionProvider(dataProvider: dataProvider)
        let transactionProvider: ITransactionProvider = EtherscanTransactionProvider(provider: ethereumKit.etherscanApiProvider)
        var transactionManager: ITransactionManager = TransactionManager(contractAddress: contractAddress, address: address, storage: storage, transactionProvider: transactionProvider, dataProvider: dataProvider, transactionBuilder: transactionBuilder)
        var balanceManager: IBalanceManager = BalanceManager(contractAddress: contractAddress, address: address, storage: storage, dataProvider: dataProvider)
        let allowanceManager = AllowanceManager(ethereumKit: ethereumKit, storage: storage, contractAddress: contractAddress, address: address)

        let erc20Kit = Kit(contractAddress: contractAddress, ethereumKit: ethereumKit, transactionManager: transactionManager, balanceManager: balanceManager, allowanceManager: allowanceManager)

        transactionManager.delegate = erc20Kit
        balanceManager.delegate = erc20Kit

        return erc20Kit
    }

    public static func clear(exceptFor excludedFiles: [String]) throws {
        let fileManager = FileManager.default
        let fileUrls = try fileManager.contentsOfDirectory(at: databaseDirectoryUrl(), includingPropertiesForKeys: nil)

        for filename in fileUrls {
            if !excludedFiles.contains(where: { filename.lastPathComponent.contains($0) }) {
                try fileManager.removeItem(at: filename)
            }
        }
    }

    private static func databaseDirectoryUrl() throws -> URL {
        let fileManager = FileManager.default

        let url = try fileManager
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("erc20-kit", isDirectory: true)

        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)

        return url
    }

}
