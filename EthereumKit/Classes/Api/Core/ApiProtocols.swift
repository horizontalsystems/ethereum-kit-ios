import RxSwift
import BigInt

protocol IRpcApiProvider {
    var source: String { get }
    func single<T>(rpc: JsonRpc<T>) -> Single<T>
}

protocol IApiStorage {
    var lastBlockHeight: Int? { get }
    func save(lastBlockHeight: Int)

    var balance: BigUInt? { get }
    func save(balance: BigUInt)
}

protocol IRpcSyncer: AnyObject {
    var delegate: IRpcSyncerDelegate? { get set }

    var source: String { get }
    var syncState: SyncState { get }

    func start()
    func stop()
    func refresh()

    func single<T>(rpc: JsonRpc<T>) -> Single<T>
}

protocol IRpcSyncerDelegate: AnyObject {
    func didUpdate(syncState: SyncState)
    func didUpdate(lastBlockLogsBloom: String)
    func didUpdate(lastBlockHeight: Int)
    func didUpdate(balance: BigUInt)
    func didUpdate(nonce: Int)
}

protocol IWebSocket: AnyObject {
    var delegate: IWebSocketDelegate? { get set }
    var source: String { get }

    func start()
    func stop()

    func send(data: Data) throws
}

protocol IWebSocketDelegate: AnyObject {
    func didUpdate(state: WebSocketState)
    func didReceive(data: Data)
}

protocol IRpcWebSocket: AnyObject {
    var delegate: IRpcWebSocketDelegate? { get set }
    var source: String { get }

    func start()
    func stop()

    func send<T>(rpc: JsonRpc<T>, rpcId: Int) throws
}

protocol IRpcWebSocketDelegate: AnyObject {
    func didUpdate(state: WebSocketState)
    func didReceive(rpcResponse: JsonRpcResponse)
    func didReceive(subscriptionResponse: RpcSubscriptionResponse)
}

enum WebSocketState {
    case connecting
    case connected
    case disconnected(error: Error)

    enum DisconnectError: Error {
        case notStarted
        case socketDisconnected(reason: String)
    }

    enum StateError: Error {
        case notConnected
    }

}
