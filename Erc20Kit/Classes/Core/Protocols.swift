import RxSwift
import BigInt
import EthereumKit

protocol IBalanceManagerDelegate: class {
    func onSyncBalanceSuccess(balance: BigUInt)
    func onSyncBalanceFailed(error: Error)
}

protocol ITransactionManagerDelegate: class {
    func onSyncStarted()
    func onSyncSuccess(transactions: [Transaction])
    func onSyncTransactionsFailed(error: Error)
}

protocol ITransactionManager {
    var transactionsObservable: Observable<[Transaction]> { get }

    func transactionsSingle(from: (hash: Data, interTransactionIndex: Int)?, limit: Int?) -> Single<[Transaction]>
    func pendingTransactions() -> [Transaction]
    func transferTransactionData(to: Address, value: BigUInt) -> TransactionData
    func sync()
}

protocol IBalanceManager {
    var delegate: IBalanceManagerDelegate? { get set }

    var balance: BigUInt? { get }
    func sync()
}

protocol IDataProvider {
    var lastBlockHeight: Int { get }
    func getTransactionStatuses(transactionHashes: [Data]) -> Single<[(Data, TransactionStatus)]>
    func getBalance(contractAddress: Address, address: Address) -> Single<BigUInt>
    func sendSingle(contractAddress: Address, transactionInput: Data, gasPrice: Int, gasLimit: Int) -> Single<Data>
}

protocol ITransactionStorage {
    var lastTransaction: TransactionRecord? { get }
    var pendingTransactions: [TransactionRecord] { get }
    func save(transaction: TransactionRecord)
    func transactionsSingle(from: (hash: Data, interTransactionIndex: Int)?, limit: Int?) -> Single<[TransactionRecord]>
}

protocol ITokenBalanceStorage {
    var balance: BigUInt? { get set }
}
