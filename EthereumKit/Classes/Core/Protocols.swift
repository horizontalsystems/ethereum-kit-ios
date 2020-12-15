import RxSwift
import BigInt

protocol IBlockchain {
    var delegate: IBlockchainDelegate? { get set }

    var source: String { get }
    func start()
    func stop()
    func refresh()

    var syncState: SyncState { get }
    var lastBlockHeight: Int? { get }
    var balance: BigUInt? { get }

    func nonceSingle() -> Single<Int>
    func sendSingle(rawTransaction: RawTransaction) -> Single<Transaction>

    func transactionReceiptSingle(transactionHash: Data) -> Single<RpcTransactionReceipt?>
    func transactionSingle(transactionHash: Data) -> Single<RpcTransaction?>
    func getStorageAt(contractAddress: Address, positionData: Data, defaultBlockParameter: DefaultBlockParameter) -> Single<Data>
    func call(contractAddress: Address, data: Data, defaultBlockParameter: DefaultBlockParameter) -> Single<Data>
    func estimateGas(to: Address?, amount: BigUInt?, gasLimit: Int?, gasPrice: Int?, data: Data?) -> Single<Int>
    func getBlock(blockNumber: Int) -> Single<RpcBlock?>
}

protocol IBlockchainDelegate: class {
    func onUpdate(lastBlockBloomFilter: BloomFilter)
    func onUpdate(lastBlockHeight: Int)
    func onUpdate(balance: BigUInt)
    func onUpdate(syncState: SyncState)
    func onUpdate(nonce: Int)
}

protocol ITransactionStorage {
    func getNotSyncedTransactions(limit: Int) -> [NotSyncedTransaction]
    func add(notSyncedTransactions: [NotSyncedTransaction])
    func update(notSyncedTransaction: NotSyncedTransaction)
    func remove(notSyncedTransaction: NotSyncedTransaction)

    func save(transaction: Transaction)
    func save(transactions: [Transaction])

    func save(transactionReceipt: TransactionReceipt)
    func getTransactionReceipt(hash: Data) -> TransactionReceipt?

    func save(logs: [TransactionLog])
    func save(internalTransactions: [InternalTransaction])

    func getHashesFromTransactions() -> [Data]
    func etherTransactionsSingle(address: Address, fromHash: Data?, limit: Int?) -> Single<[FullTransaction]>
    func transaction(hash: Data) -> FullTransaction?
    func fullTransactions(byHashes: [Data]) -> [FullTransaction]

    func transactionSyncerState(id: String) -> TransactionSyncerState?
    func save(transactionSyncerState: TransactionSyncerState)
}

protocol ITransactionsProvider {
    var source: String { get }

    func transactionsSingle(startBlock: Int) -> Single<[EtherscanTransaction]>
    func internalTransactionsSingle(startBlock: Int) -> Single<[InternalTransaction]>
}

protocol ITransactionManagerDelegate: AnyObject {
    func onUpdate(transactionsSyncState: SyncState)
    func onUpdate(transactionsWithInternal: [FullTransaction])
}
