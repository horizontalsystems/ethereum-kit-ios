import Foundation
import RxSwift

public protocol IEthereumKitDelegate: class {
    func onUpdate(transactions: [EthereumTransaction])
    func onUpdateBalance()
    func onUpdateLastBlockHeight()
    func onUpdateSyncState()
}

protocol IReachabilityManager {
    var isReachable: Bool { get }
    var reachabilitySignal: Signal { get }
}

protocol IApiConfigProvider {
    var reachabilityHost: String { get }
    var apiUrl: String { get }
}

protocol IApiProvider {
    func getGasPrice() -> Single<Decimal>
    func getLastBlockHeight() -> Single<Int>
    func getTransactionCount(address: String) -> Single<Int>

    func getBalance(address: String) -> Single<Decimal>
    func getBalanceErc20(address: String, contractAddress: String, decimal: Int) -> Single<Decimal>

    func getTransactions(address: String, startBlock: Int64) -> Single<[EthereumTransaction]>
    func getTransactionsErc20(address: String, startBlock: Int64, contracts: [ApiBlockchain.Erc20Contract]) -> Single<[EthereumTransaction]>

    func send(from: String, to: String, nonce: Int, amount: Decimal, gasPrice: Decimal, gasLimit: Int) -> Single<EthereumTransaction>
    func sendErc20(contractAddress: String, decimal: Int, from: String, to: String, nonce: Int, amount: Decimal, gasPrice: Decimal, gasLimit: Int) -> Single<EthereumTransaction>
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
    var gasPrice: Decimal? { get }

    func balance(forAddress address: String) -> Decimal?
    func lastTransactionBlockHeight(erc20: Bool) -> Int?
    func transactionsSingle(fromHash: String?, limit: Int?, contractAddress: String?) -> Single<[EthereumTransaction]>

    func save(lastBlockHeight: Int)
    func save(gasPrice: Decimal)
    func save(balance: Decimal, address: String)
    func save(transactions: [EthereumTransaction])

    func clear()
}

protocol IBlockchain {
    var ethereumAddress: String { get }
    var gasPrice: Decimal { get }
    var gasLimitEthereum: Int { get }
    var gasLimitErc20: Int { get }

    var delegate: IBlockchainDelegate? { get set }

    func start()
    func stop()
    func clear()

    func register(contractAddress: String, decimal: Int)
    func unregister(contractAddress: String)

    func sendSingle(to address: String, amount: Decimal, gasPrice: Decimal?) -> Single<EthereumTransaction>
    func sendErc20Single(to address: String, contractAddress: String, amount: Decimal, gasPrice: Decimal?) -> Single<EthereumTransaction>
}

protocol IBlockchainDelegate: class {
    func onUpdate(lastBlockHeight: Int)

    func onUpdate(balance: Decimal)
    func onUpdateErc20(balance: Decimal, contractAddress: String)

    func onUpdate(syncState: EthereumKit.SyncState)
    func onUpdateErc20(syncState: EthereumKit.SyncState, contractAddress: String)

    func onUpdate(transactions: [EthereumTransaction])
    func onUpdateErc20(transactions: [EthereumTransaction], contractAddress: String)
}
