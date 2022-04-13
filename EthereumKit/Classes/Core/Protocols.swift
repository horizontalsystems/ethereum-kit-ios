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
    func sendSingle(rawTransaction: RawTransaction, signature: Signature) -> Single<Transaction>

    func transactionReceiptSingle(transactionHash: Data) -> Single<RpcTransactionReceipt>
    func transactionSingle(transactionHash: Data) -> Single<RpcTransaction>
    func getStorageAt(contractAddress: Address, positionData: Data, defaultBlockParameter: DefaultBlockParameter) -> Single<Data>
    func call(contractAddress: Address, data: Data, defaultBlockParameter: DefaultBlockParameter) -> Single<Data>
    func estimateGas(to: Address?, amount: BigUInt?, gasLimit: Int?, gasPrice: GasPrice, data: Data?) -> Single<Int>
    func getBlock(blockNumber: Int) -> Single<RpcBlock>
    func rpcSingle<T>(rpcRequest: JsonRpc<T>) -> Single<T>
}

protocol IBlockchainDelegate: AnyObject {
    func onUpdate(lastBlockHeight: Int)
    func onUpdate(syncState: SyncState)
    func onUpdate(accountState: AccountState)
}

protocol ITransactionStorage {
    func lastTransaction() -> Transaction?
    func transaction(hash: Data) -> Transaction?
    func transactions(hashes: [Data]) -> [Transaction]
    func transactionsBefore(tags: [[String]], hash: Data?, limit: Int?) -> [Transaction]
    func save(transactions: [Transaction])

    func pendingTransactions() -> [Transaction]
    func pendingTransactions(tags: [[String]]) -> [Transaction]
    func nonPendingTransactions(nonces: [Int]) -> [Transaction]

    func internalTransactions() -> [InternalTransaction]
    func internalTransactions(hashes: [Data]) -> [InternalTransaction]
    func save(internalTransactions: [InternalTransaction])

    func save(tags: [TransactionTag])
}

public protocol ITransactionSyncer {
    func transactionsSingle(lastBlockNumber: Int) -> Single<[Transaction]>
}

protocol ITransactionManagerDelegate: AnyObject {
    func onUpdate(transactionsSyncState: SyncState)
    func onUpdate(transactionsWithInternal: [FullTransaction])
}

public protocol IMethodDecorator {
    func contractMethod(input: Data) -> ContractMethod?
}

public protocol IEventDecorator {
    func contractEventInstancesMap(transactions: [Transaction]) -> [Data: [ContractEventInstance]]
    func contractEventInstances(logs: [TransactionLog]) -> [ContractEventInstance]
}

public protocol ITransactionDecorator {
    func decoration(from: Address?, to: Address?, value: BigUInt?, contractMethod: ContractMethod?, internalTransactions: [InternalTransaction], eventInstances: [ContractEventInstance]) -> TransactionDecoration?
}

public protocol ITransactionProvider {
    func transactionsSingle(startBlock: Int) -> Single<[ProviderTransaction]>
    func internalTransactionsSingle(startBlock: Int) -> Single<[ProviderInternalTransaction]>
    func internalTransactionsSingle(transactionHash: Data) -> Single<[ProviderInternalTransaction]>
    func tokenTransactionsSingle(startBlock: Int) -> Single<[ProviderTokenTransaction]>
}
