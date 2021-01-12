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
    func getBalance(contractAddress: Address, address: Address) -> Single<BigUInt>
}

protocol ITransactionStorage {
    var lastSyncOrder: Int? { get set }
    var pendingTransactions: [TransactionCache] { get }
    func save(transaction: TransactionCache)
    func transactionsSingle(from: (hash: Data, interTransactionIndex: Int)?, limit: Int?) -> Single<[TransactionCache]>
}

protocol ITokenBalanceStorage {
    var balance: BigUInt? { get set }
}
