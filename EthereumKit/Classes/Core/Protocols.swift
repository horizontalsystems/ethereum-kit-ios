import RxSwift
import BigInt

protocol IBlockchain {
    var delegate: IBlockchainDelegate? { get set }

    var source: String { get }
    func start()
    func stop()
    func refresh()
    func syncAccountState()

    var syncState: SyncState { get }
    var lastBlockHeight: Int? { get }
    var accountState: AccountState? { get }

    func nonceSingle(defaultBlockParameter: DefaultBlockParameter) -> Single<Int>
    func sendSingle(rawTransaction: RawTransaction) -> Single<Transaction>

    func transactionReceiptSingle(transactionHash: Data) -> Single<RpcTransactionReceipt?>
    func transactionSingle(transactionHash: Data) -> Single<RpcTransaction?>
    func getStorageAt(contractAddress: Address, positionData: Data, defaultBlockParameter: DefaultBlockParameter) -> Single<Data>
    func call(contractAddress: Address, data: Data, defaultBlockParameter: DefaultBlockParameter) -> Single<Data>
    func estimateGas(to: Address?, amount: BigUInt?, gasLimit: Int?, gasPrice: Int?, data: Data?) -> Single<Int>
    func getBlock(blockNumber: Int) -> Single<RpcBlock?>
}

protocol IBlockchainDelegate: AnyObject {
    func onUpdate(lastBlockHeight: Int)
    func onUpdate(syncState: SyncState)
    func onUpdate(accountState: AccountState)
}

protocol ITransactionStorage {
    func notSyncedTransactions(limit: Int) -> [NotSyncedTransaction]
    func notSyncedInternalTransaction() -> NotSyncedInternalTransaction?

    func add(notSyncedTransactions: [NotSyncedTransaction])
    func save(notSyncedInternalTransaction: NotSyncedInternalTransaction)
    func update(notSyncedTransaction: NotSyncedTransaction)
    func remove(notSyncedTransaction: NotSyncedTransaction)
    func remove(notSyncedInternalTransaction: NotSyncedInternalTransaction)

    func save(transaction: Transaction)
    func pendingTransactions(fromTransaction: Transaction?) -> [Transaction]
    func pendingTransaction(nonce: Int) -> Transaction?

    func save(transactionReceipt: TransactionReceipt)
    func transactionReceipt(hash: Data) -> TransactionReceipt?

    func save(logs: [TransactionLog])
    func save(internalTransactions: [InternalTransaction])
    func set(tags: [TransactionTag])
    func remove(logs: [TransactionLog])

    func hashesFromTransactions() -> [Data]
    func transactionsBeforeSingle(tags: [[String]], hash: Data?, limit: Int?) -> Single<[FullTransaction]>
    func pendingTransactions(tags: [[String]]) -> [FullTransaction]
    func transaction(hash: Data) -> FullTransaction?
    func fullTransactions(byHashes: [Data]) -> [FullTransaction]
    func add(droppedTransaction: DroppedTransaction)
}

public protocol ITransactionSyncerStateStorage {
    func transactionSyncerState(id: String) -> TransactionSyncerState?
    func save(transactionSyncerState: TransactionSyncerState)
}

protocol ITransactionSyncerListener: AnyObject {
    func onTransactionsSynced(fullTransactions: [FullTransaction])
}

public protocol ITransactionSyncer {
    var id: String { get }
    var state: SyncState { get }
    var stateObservable: Observable<SyncState> { get }

    func set(delegate: ITransactionSyncerDelegate)
    func start()
    func onEthereumSynced()
    func onLastBlockNumber(blockNumber: Int)
    func onUpdateAccountState(accountState: AccountState)
}

public protocol ITransactionSyncerDelegate {
    var notSyncedTransactionsSignal: PublishSubject<Void> { get }
    func transactionSyncerState(id: String) -> TransactionSyncerState?
    func update(transactionSyncerState: TransactionSyncerState)
    func add(notSyncedTransactions: [NotSyncedTransaction])
    func notSyncedTransactions(limit: Int) -> [NotSyncedTransaction]
    func remove(notSyncedTransaction: NotSyncedTransaction)
    func update(notSyncedTransaction: NotSyncedTransaction)
}

protocol ITransactionManagerDelegate: AnyObject {
    func onUpdate(transactionsSyncState: SyncState)
    func onUpdate(transactionsWithInternal: [FullTransaction])
}

public protocol IDecorator {
    func decorate(transactionData: TransactionData, fullTransaction: FullTransaction?) -> ContractMethodDecoration?
    func decorate(logs: [TransactionLog]) -> [ContractEventDecoration]
}

public protocol ITransactionWatcher {
    func needInternalTransactions(fullTransaction: FullTransaction) -> Bool
}
