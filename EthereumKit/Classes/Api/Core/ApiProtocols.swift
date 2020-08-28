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
    func stop(error: Error)
    func refresh()

    func single<T>(rpc: JsonRpc<T>) -> Single<T>
}

protocol IRpcSyncerDelegate: AnyObject {
    func didUpdate(syncState: SyncState)
    func didUpdate(lastBlockHeight: Int)
    func didUpdate(balance: BigUInt)
}

protocol IWebSocket: AnyObject {
    var delegate: IWebSocketDelegate? { get set }

    func connect()
    func disconnect(error: Error)
    func send<T>(rpc: JsonRpc<T>, onSuccess: @escaping (T) -> (), onError: @escaping (Error) -> ())
    func subscribe<T>(subscription: RpcSubscription<T>, onSuccess: @escaping () -> (), onError: @escaping (Error) -> (), successHandler: @escaping (T) -> (), errorHandler: @escaping (Error) -> ())
}

protocol IWebSocketDelegate: AnyObject {
    func didConnect()
    func didDisconnect(error: Error)
}
