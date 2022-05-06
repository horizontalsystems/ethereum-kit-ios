import RxSwift
import BigInt
import HsToolKit

protocol IRpcApiProvider {
    var source: String { get }
    func single<T>(rpc: JsonRpc<T>) -> Single<T>
}

protocol IApiStorage {
    var lastBlockHeight: Int? { get }
    func save(lastBlockHeight: Int)

    var accountState: AccountState? { get }
    func save(accountState: AccountState)
}

protocol IRpcSyncer: AnyObject {
    var delegate: IRpcSyncerDelegate? { get set }

    var source: String { get }
    var state: SyncerState { get }

    func start()
    func stop()

    func single<T>(rpc: JsonRpc<T>) -> Single<T>
}

protocol IRpcSyncerDelegate: AnyObject {
    func didUpdate(state: SyncerState)
    func didUpdate(lastBlockHeight: Int)
}

protocol IRpcWebSocket: AnyObject {
    var delegate: IRpcWebSocketDelegate? { get set }
    var source: String { get }

    func start()
    func stop()

    func send<T>(rpc: JsonRpc<T>, rpcId: Int) throws
}

protocol IRpcWebSocketDelegate: AnyObject {
    func didUpdate(socketState: WebSocketState)
    func didReceive(rpcResponse: JsonRpcResponse)
    func didReceive(subscriptionResponse: RpcSubscriptionResponse)
}

enum SyncerState {
    case preparing
    case ready
    case notReady(error: Error)
}

extension SyncerState: Equatable {

    public static func ==(lhs: SyncerState, rhs: SyncerState) -> Bool {
        switch (lhs, rhs) {
        case (.preparing, .preparing): return true
        case (.ready, .ready): return true
        case (.notReady(let lhsError), .notReady(let rhsError)): return "\(lhsError)" == "\(rhsError)"
        default: return false
        }
    }

}
