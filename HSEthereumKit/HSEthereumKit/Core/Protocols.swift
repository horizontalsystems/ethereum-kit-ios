import Foundation
import RxSwift


protocol IPeerDelegate: class {
    func blocksReceived(blocks: [Block])
    func connected()
}

protocol IDevP2PPeerDelegate: class {
    func connectionEstablished()
    func connectionDidDisconnect(withError error: Error?)
    func connection(didReceiveMessage message: IMessage)
}

protocol IConnectionDelegate: class {
    func connectionEstablished()
    func connectionKey() -> ECKey
    func connectionDidDisconnect(withError error: Error?)
    func connection(didReceiveMessage message: IMessage)
}

protocol IPeerConnection: class {
    var delegate: IConnectionDelegate? { get set }
    var logName: String { get }
    func connect()
    func disconnect(error: Error?)
    func send(message: IMessage)
}

protocol INetwork {
    var id: Int { get }
    var genesisBlockHash: Data { get }
    var checkpointBlock: Block{ get }
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
    func getGasPrice() -> Single<Wei>
    func getGasLimit(address: String, data: Data?) -> Single<Wei>
    func getBalance(address: String, contractAddress: String?, blockParameter: BlockParameter) -> Single<Balance>
    func getTransactions(address: String, erc20: Bool, startBlock: Int64) -> Single<Transactions>
    func getBlockNumber() -> Single<Int>
    func getTransactionCount(address: String, blockParameter: BlockParameter) -> Single<Int>
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
