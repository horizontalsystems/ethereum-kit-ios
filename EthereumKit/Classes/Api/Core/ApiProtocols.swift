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
    func didUpdate(state: AccountState)
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
