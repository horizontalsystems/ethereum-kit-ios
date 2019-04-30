import RxSwift
import BigInt
import EthereumKit

protocol IBalanceManagerDelegate: class {
    func onSyncBalanceSuccess(balance: BigUInt)
    func onSyncBalanceError()
}

protocol ITransactionManagerDelegate: class {
    func onSyncSuccess(transactions: [Transaction])
    func onSyncTransactionsError()
}

protocol ITransactionBuilder {
    func transferTransactionInput(to toAddress: Data, value: BigUInt) -> Data
}

protocol ITransactionManager {
    var delegate: ITransactionManagerDelegate? { get set }

    var lastTransactionBlockHeight: Int? { get }
    func transactionsSingle(from: (hash: Data, index: Int)?, limit: Int?) -> Single<[Transaction]>

    func sync()
    func sendSingle(to: Data, value: BigUInt, gasPrice: Int, gasLimit: Int) -> Single<Transaction>

    func clear()
}

protocol IBalanceManager {
    var delegate: IBalanceManagerDelegate? { get set }

    var balance: BigUInt? { get }
    func sync()

    func clear()
}

protocol IDataProvider {
    var lastBlockHeight: Int { get }
    func getTransactionLogs(contractAddress: Data, address: Data, from: Int, to: Int) -> Single<[EthereumLog]>
    func getBalance(contractAddress: Data, address: Data) -> Single<BigUInt>
    func sendSingle(contractAddress: Data, transactionInput: Data, gasPrice: Int, gasLimit: Int) -> Single<Data>
}

protocol ITransactionStorage {
    var lastTransactionBlockHeight: Int? { get }
    var pendingTransactions: [Transaction] { get }
    func transactionsSingle(from: (hash: Data, index: Int)?, limit: Int?) -> Single<[Transaction]>
    func save(transactions: [Transaction])
    func update(transaction: Transaction)
    func clearTransactions()
}

protocol ITokenBalanceStorage {
    var balance: BigUInt? { get set }
}
