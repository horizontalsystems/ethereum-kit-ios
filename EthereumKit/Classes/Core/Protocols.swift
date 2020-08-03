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

    func sendSingle(rawTransaction: RawTransaction) -> Single<Transaction>

    func getLogsSingle(address: Address?, topics: [Any?], fromBlock: Int, toBlock: Int, pullTimestamps: Bool) -> Single<[EthereumLog]>
    func transactionReceiptStatusSingle(transactionHash: Data) -> Single<TransactionStatus>
    func transactionExistSingle(transactionHash: Data) -> Single<Bool>
    func getStorageAt(contractAddress: Address, positionData: Data, defaultBlockParameter: DefaultBlockParameter) -> Single<Data>
    func call(contractAddress: Address, data: Data, defaultBlockParameter: DefaultBlockParameter) -> Single<Data>
    func estimateGas(to: Address, amount: BigUInt?, gasLimit: Int?, gasPrice: Int?, data: Data?) -> Single<Int>
}

protocol IBlockchainDelegate: class {
    func onUpdate(lastBlockHeight: Int)
    func onUpdate(balance: BigUInt)
    func onUpdate(syncState: SyncState)
}

protocol ITransactionManager {
    var syncState: SyncState { get }
    var source: String { get }
    var delegate: ITransactionManagerDelegate? { get set }

    func refresh()
    func transactionsSingle(fromHash: Data?, limit: Int?) -> Single<[TransactionWithInternal]>
    func transaction(hash: Data) -> TransactionWithInternal?
    func handle(sentTransaction: Transaction)
}

protocol ITransactionStorage {
    var lastTransaction: Transaction? { get }

    func transactionsSingle(fromHash: Data?, limit: Int?) -> Single<[TransactionWithInternal]>
    func transaction(hash: Data) -> TransactionWithInternal?
    func save(transactions: [Transaction])
}

protocol IInternalTransactionStorage {
    var lastInternalTransactionBlockHeight: Int? { get }
    func save(internalTransactions: [InternalTransaction])
}

protocol ITransactionsProvider {
    var source: String { get }

    func transactionsSingle(startBlock: Int) -> Single<[Transaction]>
    func internalTransactionsSingle(startBlock: Int) -> Single<[InternalTransaction]>
}

protocol ITransactionManagerDelegate: AnyObject {
    func onUpdate(transactionsSyncState: SyncState)
    func onUpdate(transactionsWithInternal: [TransactionWithInternal])
}
