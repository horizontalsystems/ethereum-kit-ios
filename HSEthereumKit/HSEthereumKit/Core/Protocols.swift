import RxSwift

protocol IStorage {
    func transactionsSingle(fromHash: Data?, limit: Int?, contractAddress: Data?) -> Single<[Transaction]>
    func save(transactions: [Transaction])

    func clear()
}

protocol IBlockchain {
    var delegate: IBlockchainDelegate? { get set }

    var address: Data { get }

    func start()
    func clear()

    var syncState: EthereumKit.SyncState { get }
    func syncStateErc20(contractAddress: Data) -> EthereumKit.SyncState

    var lastBlockHeight: Int? { get }

    var balance: BInt? { get }
    func balanceErc20(contractAddress: Data) -> BInt?

    func transactionsSingle(fromHash: Data?, limit: Int?) -> Single<[Transaction]>
    func transactionsErc20Single(contractAddress: Data, fromHash: Data?, limit: Int?) -> Single<[Transaction]>

    func sendSingle(rawTransaction: RawTransaction) -> Single<Transaction>

    func register(contractAddress: Data)
    func unregister(contractAddress: Data)
}

protocol IBlockchainDelegate: class {
    func onUpdate(lastBlockHeight: Int)

    func onUpdate(balance: BInt)
    func onUpdateErc20(balance: BInt, contractAddress: Data)

    func onUpdate(syncState: EthereumKit.SyncState)
    func onUpdateErc20(syncState: EthereumKit.SyncState, contractAddress: Data)

    func onUpdate(transactions: [Transaction])
    func onUpdateErc20(transactions: [Transaction], contractAddress: Data)
}

protocol IAddressValidator {
    func validate(address: String) throws
}

protocol IReachabilityManager {
    var isReachable: Bool { get }
    var reachabilitySignal: Signal { get }
}

protocol IApiConfigProvider {
    var reachabilityHost: String { get }
    var apiUrl: String { get }
}
