import RxSwift
import BigInt

protocol IBlockchain {
    var delegate: IBlockchainDelegate? { get set }

    func start()
    func stop()
    func refresh()

    var syncState: EthereumKit.SyncState { get }
    var lastBlockHeight: Int? { get }
    var balance: BigUInt? { get }

    func sendSingle(rawTransaction: RawTransaction) -> Single<Transaction>

    func getLogsSingle(address: Data?, topics: [Any?], fromBlock: Int, toBlock: Int, pullTimestamps: Bool) -> Single<[EthereumLog]>
    func getStorageAt(contractAddress: Data, positionData: Data, blockHeight: Int) -> Single<Data>
    func call(contractAddress: Data, data: Data, blockHeight: Int?) -> Single<Data>
}

protocol IBlockchainDelegate: class {
    func onUpdate(lastBlockHeight: Int)
    func onUpdate(balance: BigUInt)
    func onUpdate(syncState: EthereumKit.SyncState)
}

protocol ITransactionStorage {
    var lastTransactionBlockHeight: Int? { get }

    func transactionsSingle(fromHash: Data?, limit: Int?, contractAddress: Data?) -> Single<[Transaction]>
    func save(transactions: [Transaction])
}

protocol ITransactionsProvider {
    func transactionsSingle(startBlock: Int) -> Single<[Transaction]>
}

protocol ITransactionManagerDelegate: AnyObject {
    func onUpdate(transactions: [Transaction])
}

protocol IAddressValidator {
    func validate(address: String) throws
}

protocol IReachabilityManager {
    var isReachable: Bool { get }
    var reachabilitySignal: Signal { get }
}
