import Foundation
import RxSwift

protocol IReachabilityManager {
    var isReachable: Bool { get }
    var reachabilitySignal: Signal { get }
}

protocol IApiConfigProvider {
    var reachabilityHost: String { get }
    var apiUrl: String { get }
}

protocol IApiProvider {
    func gasPriceInWeiSingle() -> Single<GasPrice>
    func lastBlockHeightSingle() -> Single<Int>
    func transactionCountSingle(address: String) -> Single<Int>

    func balanceSingle(address: String) -> Single<String>
    func balanceErc20Single(address: String, contractAddress: String) -> Single<String>

    func transactionsSingle(address: String, startBlock: Int64) -> Single<[EthereumTransaction]>
    func transactionsErc20Single(address: String, startBlock: Int64) -> Single<[EthereumTransaction]>

    func sendSingle(from: String, to: String, nonce: Int, amount: String, gasPriceInWei: Int, gasLimit: Int) -> Single<EthereumTransaction>
    func sendErc20Single(contractAddress: String, from: String, to: String, nonce: Int, amount: String, gasPriceInWei: Int, gasLimit: Int) -> Single<EthereumTransaction>
}

protocol IPeriodicTimer {
    var delegate: IPeriodicTimerDelegate? { get set }
    func schedule()
    func invalidate()
}

protocol IPeriodicTimerDelegate: class {
    func onFire()
}

protocol IRefreshKitDelegate: class {
    func onRefresh()
    func onDisconnect()
}

protocol IRefreshManager {
    func didRefresh()
}

protocol IAddressValidator {
    func validate(address: String) throws
}

protocol IStorage {
    var lastBlockHeight: Int? { get }

    func balance(forAddress address: String) -> String?
    func transactionsSingle(fromHash: String?, limit: Int?, contractAddress: String?) -> Single<[EthereumTransaction]>

    func clear()
}

protocol IApiStorage: IStorage {
    var gasPriceInWei: GasPrice? { get }
    func lastTransactionBlockHeight(erc20: Bool) -> Int?

    func save(lastBlockHeight: Int)
    func save(gasPriceInWei: GasPrice)
    func save(balance: String, address: String)
    func save(transactions: [EthereumTransaction])
}

protocol IBlockchain {
    var ethereumAddress: String { get }
    var gasPriceInWei: GasPrice { get }
    var gasLimitEthereum: Int { get }
    var gasLimitErc20: Int { get }

    var delegate: IBlockchainDelegate? { get set }

    func start()
    func clear()

    var syncState: EthereumKit.SyncState { get }
    func syncState(contractAddress: String) -> EthereumKit.SyncState

    func register(contractAddress: String)
    func unregister(contractAddress: String)

    func sendSingle(to address: String, amount: String, gasPriceInWei: Int?) -> Single<EthereumTransaction>
    func sendErc20Single(to address: String, contractAddress: String, amount: String, gasPriceInWei: Int?) -> Single<EthereumTransaction>
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
