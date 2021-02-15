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
                    self?.onUpdate(bloomFilter: $0)
                })
                .disposed(by: disposeBag)
    }

    private func onUpdate(bloomFilter: BloomFilter) {
        if bloomFilter.mayContain(contractAddress: contractAddress) {
            balanceManager.sync()
        }
    }

    private func onUpdateSyncState(syncState: EthereumKit.SyncState) {
        switch syncState {
        case .synced:
            state.syncState = .syncing(progress: nil)
            balanceManager.sync()
        case .syncing:
            state.syncState = .syncing(progress: nil)
        case .notSynced(let error):
            state.syncState = .notSynced(error: error)
        }
    }

}

extension Kit {

    public func start() {
        transactionManager.sync()
    }

    public func stop() {
        ethereumKit.removeSyncer(byId: Kit.syncerId(contractAddress: contractAddress))
    }

    public func refresh() {
    }

    public var syncState: SyncState {
        state.syncState
    }

    public var transactionsSyncState: SyncState {
        ethereumKit.transactionsSyncState
    }

    public var balance: BigUInt? {
        state.balance
    }

    public func transactionsSingle(from: (hash: Data, interTransactionIndex: Int)?, limit: Int?) throws -> Single<[Transaction]> {
        transactionManager.transactionsSingle(from: from, limit: limit)
    }

    public func pendingTransactions() -> [Transaction] {
        transactionManager.pendingTransactions()
    }

    public var syncStateObservable: Observable<SyncState> {
        state.syncStateSubject.asObservable()
    }

    public var transactionsSyncStateObservable: Observable<SyncState> {
        ethereumKit.transactionsSyncStateObservable
    }

    public var balanceObservable: Observable<BigUInt> {
        state.balanceSubject.asObservable()
    }

    public var transactionsObservable: Observable<[Transaction]> {
        transactionManager.transactionsObservable
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

    public func transferTransactionData(to: Address, value: BigUInt) -> TransactionData {
        transactionManager.transferTransactionData(to: to, value: value)
    }

}

extension Kit: IBalanceManagerDelegate {

    func onSyncBalanceSuccess(balance: BigUInt) {
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

        ContractMethodFactories.shared.register(factory: ApproveMethodFactory())
        ContractMethodFactories.shared.register(factory: TransferMethodFactory())

        let address = ethereumKit.address
        let storage: ITransactionStorage & ITokenBalanceStorage = try GrdbStorage(databaseDirectoryUrl: databaseDirectoryUrl(), databaseFileName: databaseFileName)

        let dataProvider: IDataProvider = DataProvider(ethereumKit: ethereumKit)
        let transactionSyncer = Erc20TransactionSyncer(provider: ethereumKit.etherscanService, contractAddress: contractAddress, id: syncerId(contractAddress: contractAddress))
        let transactionManager = TransactionManager(contractAddress: contractAddress, ethereumKit: ethereumKit, contractMethodFactories: ContractMethodFactories.shared, storage: storage)
        let balanceManager = BalanceManager(contractAddress: contractAddress, address: address, storage: storage, dataProvider: dataProvider)
        let allowanceManager = AllowanceManager(ethereumKit: ethereumKit, contractAddress: contractAddress, address: address)

        let erc20Kit = Kit(contractAddress: contractAddress, ethereumKit: ethereumKit, transactionManager: transactionManager, balanceManager: balanceManager, allowanceManager: allowanceManager)

        balanceManager.delegate = erc20Kit
        ethereumKit.add(syncer: transactionSyncer)

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

    private static func syncerId(contractAddress: Address) -> String {
        "erc20_transaction_syncer_\(contractAddress.hex)"
    }

}
