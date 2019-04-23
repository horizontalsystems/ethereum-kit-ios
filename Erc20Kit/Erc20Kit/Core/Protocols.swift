import RxSwift
import EthereumKit

protocol IBalanceManagerDelegate: class {
    func onUpdate(balance: TokenBalance, contractAddress: Data)
    func onSyncBalanceSuccess(contractAddress: Data)
    func onSyncBalanceError(contractAddress: Data)
}

protocol ITransactionManagerDelegate: class {
    func onSyncSuccess(transactions: [Transaction])
    func onSyncTransactionsError()
}

protocol ITransactionsProvider {
    func transactionsErc20Single(address: Data, startBlock: Int) -> Single<[Transaction]>
}

protocol ITransactionBuilder {
    func transferTransactionInput(to toAddress: Data, value: BInt) -> Data
}

protocol ITransactionManager {
    var delegate: ITransactionManagerDelegate? { get set }

    func lastTransactionBlockHeight(contractAddress: Data) -> Int?
    func transactionsSingle(contractAddress: Data, from: (hash: Data, index: Int)?, limit: Int?) -> Single<[Transaction]>

    func sync()
    func sendSingle(contractAddress: Data, to: Data, value: BInt, gasPrice: Int) -> Single<Transaction>

    func clear()
}

protocol IBalanceManager {
    var delegate: IBalanceManagerDelegate? { get set }

    func balance(contractAddress: Data) -> TokenBalance
    func sync(blockHeight: Int, contractAddress: Data, balancePosition: Int)

    func clear()
}

protocol IDataProvider {
    var lastBlockHeight: Int { get }
    func getTransactions(from: Int, to: Int, address: Data) -> Single<[Transaction]>
    func getStorageValue(contractAddress: Data, position: Int, address: Data, blockHeight: Int) -> Single<BInt>
    func sendSingle(contractAddress: Data, transactionInput: Data, gasPrice: Int) -> Single<Data>
}

protocol ITokenHolder {
    var contractAddresses: [Data] { get }

    func syncState(contractAddress: Data) throws -> Erc20Kit.SyncState
    func balance(contractAddress: Data) throws -> TokenBalance
    func balancePosition(contractAddress: Data) throws -> Int

    func syncStateSignal(contractAddress: Data) throws -> Signal
    func balanceSignal(contractAddress: Data) throws -> Signal
    func transactionsSubject(contractAddress: Data) throws -> PublishSubject<[TransactionInfo]>

    func register(contractAddress: Data, balancePosition: Int, balance: TokenBalance)
    func unregister(contractAddress: Data) throws
    func set(syncState: Erc20Kit.SyncState, contractAddress: Data) throws
    func set(balance: TokenBalance, contractAddress: Data) throws

    func clear()
}

protocol ITransactionStorage {
    var lastTransactionBlockHeight: Int? { get }
    func lastTransactionBlockHeight(contractAddress: Data) -> Int?
    func transactionsCount(contractAddress: Data) -> Int
    func transactionsSingle(contractAddress: Data, from: (hash: Data, index: Int)?, limit: Int?) -> Single<[Transaction]>
    func save(transactions: [Transaction])
    func update(transaction: Transaction)
    func clearTransactions()
}

protocol ITokenBalanceStorage {
    func tokenBalance(contractAddress: Data) -> TokenBalance?
    func save(tokenBalance: TokenBalance)
    func clearTokenBalances()
}
