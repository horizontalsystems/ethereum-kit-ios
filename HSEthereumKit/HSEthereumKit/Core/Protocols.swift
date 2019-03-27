import RxSwift

protocol IBlockchain {
    var delegate: IBlockchainDelegate? { get set }

    var address: Address { get }

    func start()
    func clear()

    var syncState: EthereumKit.SyncState { get }
    func syncStateErc20(contractAddress: String) -> EthereumKit.SyncState

    var lastBlockHeight: Int? { get }

    var balance: String? { get }
    func balanceErc20(contractAddress: String) -> String?

    func transactionsSingle(fromHash: String?, limit: Int?) -> Single<[EthereumTransaction]>
    func transactionsErc20Single(contractAddress: String, fromHash: String?, limit: Int?) -> Single<[EthereumTransaction]>

    func sendSingle(rawTransaction: RawTransaction) -> Single<EthereumTransaction>

    func register(contractAddress: String)
    func unregister(contractAddress: String)
}

protocol IBlockchainDelegate: class {
    func onUpdate(lastBlockHeight: Int)

    func onUpdate(balance: String)
    func onUpdateErc20(balance: String, contractAddress: String)

    func onUpdate(syncState: EthereumKit.SyncState)
    func onUpdateErc20(syncState: EthereumKit.SyncState, contractAddress: String)

    func onUpdate(transactions: [EthereumTransaction])
    func onUpdateErc20(transactions: [EthereumTransaction], contractAddress: String)
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
