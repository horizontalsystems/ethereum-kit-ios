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

protocol ITransactionBuilder {
    func transferTransactionInput(to toAddress: Address, value: BigUInt) -> Data
}

protocol ITransactionManager {
    var delegate: ITransactionManagerDelegate? { get set }

    func transactionsSingle(from: (hash: Data, interTransactionIndex: Int)?, limit: Int?) -> Single<[Transaction]>
    func transaction(hash: Data, interTransactionIndex: Int) -> Transaction?

    func immediateSync()
    func delayedSync(expectTransaction: Bool)
    func transactionContractData(to: Address, value: BigUInt) -> Data
    func sendSingle(to: Address, value: BigUInt, gasPrice: Int, gasLimit: Int) -> Single<Transaction>
    func pendingTransactions() -> [Transaction]
}

protocol ITransactionProvider {
    func transactions(contractAddress: Address, address: Address, from: Int, to: Int) -> Single<[Transaction]>
}

protocol IBalanceManager {
    var delegate: IBalanceManagerDelegate? { get set }

    var balance: BigUInt? { get }
    func sync()
}

protocol IDataProvider {
    var lastBlockHeight: Int { get }
    func getTransactionLogs(contractAddress: Address, address: Address, from: Int, to: Int) -> Single<[EthereumLog]>
    func getTransactionStatuses(transactionHashes: [Data]) -> Single<[(Data, TransactionStatus)]>
    func getBalance(contractAddress: Address, address: Address) -> Single<BigUInt>
    func sendSingle(contractAddress: Address, transactionInput: Data, gasPrice: Int, gasLimit: Int) -> Single<Data>
}

protocol ITransactionStorage {
    var lastTransactionBlockHeight: Int? { get }
    var pendingTransactions: [Transaction] { get }
    func transactionsSingle(from: (hash: Data, interTransactionIndex: Int)?, limit: Int?) -> Single<[Transaction]>
    func transaction(hash: Data, interTransactionIndex: Int) -> Transaction?
    func save(transactions: [Transaction])
    func update(transaction: Transaction)
}

protocol ITokenBalanceStorage {
    var balance: BigUInt? { get set }
}
