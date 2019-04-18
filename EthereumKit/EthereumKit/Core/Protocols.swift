import RxSwift

public protocol IRequest {
    var id: Int { get }
}

public protocol IResponse {
    var id: Int { get }
}

public protocol IEthereumKitDelegate: class {
    func onClear()

    func onUpdate(transactions: [TransactionInfo])
    func onUpdateBalance()
    func onUpdateLastBlockHeight()
    func onUpdateSyncState()
}

extension IEthereumKitDelegate {
    public func onClear() {
    }

    public func onUpdate(transactions: [TransactionInfo]) {
    }

    public func onUpdateBalance() {
    }

    public func onUpdateLastBlockHeight() {
    }

    public func onUpdateSyncState() {
    }
}

protocol ITransactionsProvider {
    func transactionsSingle(address: Data, startBlock: Int) -> Single<[Transaction]>
}

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
    var lastBlockHeight: Int? { get }
    var balance: BInt? { get }

    func transactionsSingle(fromHash: Data?, limit: Int?) -> Single<[Transaction]>
    func sendSingle(rawTransaction: RawTransaction) -> Single<Transaction>

    func getLogsSingle(address: Data?, topics: [Any], fromBlock: Int, toBlock: Int, pullTimestamps: Bool) -> Single<[EthereumLog]>
    func getStorageAt(contractAddress: Data, positionData: Data, blockHeight: Int) -> Single<Data>
}

protocol IBlockchainDelegate: class {
    func onUpdate(lastBlockHeight: Int)
    func onUpdate(balance: BInt)
    func onUpdate(syncState: EthereumKit.SyncState)
    func onUpdate(transactions: [Transaction])
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
