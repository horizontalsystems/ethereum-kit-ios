import RxSwift
import EthereumKit

protocol IBalanceManagerDelegate: class {
    func onSyncBalanceSuccess(balance: BInt)
    func onSyncBalanceError()
}

protocol ITransactionManagerDelegate: class {
    func onSyncSuccess(transactions: [Transaction])
    func onSyncTransactionsError()
}

protocol ITransactionBuilder {
    func transferTransactionInput(to toAddress: Data, value: BInt) -> Data
}

protocol ITransactionManager {
    var delegate: ITransactionManagerDelegate? { get set }

    var lastTransactionBlockHeight: Int? { get }
    func transactionsSingle(from: (hash: Data, index: Int)?, limit: Int?) -> Single<[Transaction]>

    func sync()
    func sendSingle(to: Data, value: BInt, gasPrice: Int, gasLimit: Int) -> Single<Transaction>

    func clear()
}

protocol IBalanceManager {
    var delegate: IBalanceManagerDelegate? { get set }

    var balance: BInt? { get }
    func sync()

    func clear()
}

protocol IDataProvider {
    var lastBlockHeight: Int { get }
    func getTransactions(contractAddress: Data, address: Data, from: Int, to: Int) -> Single<[Transaction]>
    func getBalance(contractAddress: Data, address: Data) -> Single<BInt>
    func sendSingle(contractAddress: Data, transactionInput: Data, gasPrice: Int, gasLimit: Int) -> Single<Data>
}

protocol ITransactionStorage {
    var lastTransactionBlockHeight: Int? { get }
    func transactionsSingle(from: (hash: Data, index: Int)?, limit: Int?) -> Single<[Transaction]>
    func save(transactions: [Transaction])
    func update(transaction: Transaction)
    func clearTransactions()
}

protocol ITokenBalanceStorage {
    var balance: BInt? { get set }
}
