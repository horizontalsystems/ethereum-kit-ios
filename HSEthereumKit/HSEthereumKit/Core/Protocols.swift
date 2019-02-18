import Foundation
import RxSwift

public protocol EthereumKitDelegate: class {
    func onUpdate(transactions: [EthereumTransaction])
    func onUpdateBalance()
    func onUpdateLastBlockHeight()
    func onUpdateState()
}

public protocol Erc20KitDelegate: EthereumKitDelegate {
    var contractAddress: String { get }
    var decimal: Int { get }
}

extension EthereumKit {

    public enum SyncState {
        case synced
        case syncing
        case notSynced
    }

}

protocol IReachabilityManager {
    var isReachable: Bool { get }
    var reachabilitySignal: Signal { get }
}

protocol IApiConfigProvider {
    var reachabilityHost: String { get }
    var apiUrl: String { get }
}

protocol IGethProviderProtocol {
    func getGasPrice() -> Single<Decimal>
    func getLastBlockHeight() -> Single<Int>
    func getTransactionCount(address: String, blockParameter: BlockParameter) -> Single<Int>

    func getBalance(address: String, blockParameter: BlockParameter) -> Single<Decimal>
    func getBalanceErc20(address: String, contractAddress: String, decimal: Int, blockParameter: BlockParameter) -> Single<Decimal>

    func getTransactions(address: String, startBlock: Int64, rate: Decimal) -> Single<[EthereumTransaction]>
    func getTransactionsErc20(address: String, startBlock: Int64, contracts: [Blockchain.Erc20Contract]) -> Single<[EthereumTransaction]>

    func sendRawTransaction(rawTransaction: String) -> Single<SentTransaction>
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
    var delegate: IBlockchainDelegate? { get set }

    func start()
    func stop()
    func clear()

    func register(contractAddress: String, decimal: Int)
    func unregister(contractAddress: String)

    func send(to address: String, value: Decimal, gasPrice: Decimal, completion: ((Error?) -> ())?)
    func erc20Send(to address: String, contractAddress: String, value: Decimal, gasPrice: Decimal, completion: ((Error?) -> ())?)
}

protocol IBlockchainDelegate: class {
    func onUpdate(lastBlockHeight: Int)
    func onUpdate(gasPrice: Decimal)

    func onUpdate(state: EthereumKit.SyncState)
    func onUpdateErc20(state: EthereumKit.SyncState, contractAddress: String)

    func onUpdate(balance: Decimal)
    func onUpdateErc20(balance: Decimal, contractAddress: String)

    func onUpdate(transactions: [EthereumTransaction])
    func onUpdateErc20(transactions: [EthereumTransaction], contractAddress: String)
}
