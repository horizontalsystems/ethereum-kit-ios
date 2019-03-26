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

protocol IApiStorage {
    var lastBlockHeight: Int? { get }

    func balance(forAddress address: String) -> String?
    func transactionsSingle(fromHash: String?, limit: Int?, contractAddress: String?) -> Single<[EthereumTransaction]>

    func lastTransactionBlockHeight(erc20: Bool) -> Int?

    func save(lastBlockHeight: Int)
    func save(balance: String, address: String)
    func save(transactions: [EthereumTransaction])

    func clear()
}

protocol IBlockchain {
    var delegate: IBlockchainDelegate? { get set }

    var address: String { get }

    func start()
    func clear()

    var syncState: EthereumKit.SyncState { get }
    func syncStateErc20(contractAddress: String) -> EthereumKit.SyncState

    var lastBlockHeight: Int? { get }

    var balance: String? { get }
    func balanceErc20(contractAddress: String) -> String?

    func transactionsSingle(fromHash: String?, limit: Int?) -> Single<[EthereumTransaction]>
    func transactionsErc20Single(contractAddress: String, fromHash: String?, limit: Int?) -> Single<[EthereumTransaction]>

    func sendSingle(to toAddress: String, amount: String, gasPrice: Int, gasLimit: Int) -> Single<EthereumTransaction>
    func sendErc20Single(contractAddress: String, to toAddress: String, amount: String, gasPrice: Int, gasLimit: Int) -> Single<EthereumTransaction>

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
