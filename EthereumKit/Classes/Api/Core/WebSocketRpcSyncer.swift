import RxSwift
import Starscream
import BigInt
import HsToolKit

class WebSocketRpcSyncer {
    typealias RpcHandler = (JsonRpcResponse) -> ()
    typealias SubscriptionHandler = (RpcSubscriptionResponse) -> ()

    weak var delegate: IRpcSyncerDelegate?

    private let address: Address
    private let socket: IWebSocket
    private var logger: Logger?

    private var currentRpcId = 0
    private var rpcHandlers = [Int: RpcHandler]()
    private var subscriptionHandlers = [Int: SubscriptionHandler]()

    private var isSubscribedToNewHeads = false

    private let queue = DispatchQueue(label: "io.horizontal-systems.ethereum-kit.web-socket-rpc-syncer", qos: .userInitiated)

    private(set) var syncState: SyncState = .notSynced(error: Kit.SyncError.notStarted) {
        didSet {
            if syncState != oldValue {
                delegate?.didUpdate(syncState: syncState)
            }
        }
    }

    private init(address: Address, socket: IWebSocket, logger: Logger? = nil) {
        self.address = address
        self.socket = socket
        self.logger = logger
    }

    private var nextRpcId: Int {
        currentRpcId += 1
        return currentRpcId
    }

    private func send<T>(rpc: JsonRpc<T>, handler: @escaping RpcHandler) throws {
        let rpcId = nextRpcId

        let parameters = rpc.parameters(id: rpcId)
        let data = try JSONSerialization.data(withJSONObject: parameters)

        try socket.send(data: data)

        rpcHandlers[rpcId] = handler

        logger?.debug("Send RPC: \(parameters)")
    }

    func send<T>(rpc: JsonRpc<T>, onSuccess: @escaping (T) -> (), onError: @escaping (Error) -> ()) {
        queue.async { [weak self] in
            do {
                try self?.send(rpc: rpc) { response in
                    do {
                        onSuccess(try rpc.parse(response: response))
                    } catch {
                        onError(error)
                    }
                }
            } catch {
                onError(error)
            }
        }
    }

    func subscribe<T>(subscription: RpcSubscription<T>, onSuccess: @escaping () -> (), onError: @escaping (Error) -> (), successHandler: @escaping (T) -> (), errorHandler: @escaping (Error) -> ()) {
        send(
                rpc: SubscribeJsonRpc(params: subscription.params),
                onSuccess: { [weak self] subscriptionId in
                    self?.subscriptionHandlers[subscriptionId] = { response in
                        do {
                            successHandler(try subscription.parse(result: response.params.result))
                        } catch {
                            errorHandler(error)
                        }
                    }
                    onSuccess()
                },
                onError: onError
        )
    }

    private func handle(rpcResponse: JsonRpcResponse) throws {
        let handler = rpcHandlers.removeValue(forKey: rpcResponse.id)
        handler?(rpcResponse)
    }

    private func handle(subscriptionResponse: RpcSubscriptionResponse) throws {
        subscriptionHandlers[subscriptionResponse.params.subscriptionId]?(subscriptionResponse)
    }

    private func fetchLastBlockHeight() {
        send(
                rpc: BlockNumberJsonRpc(),
                onSuccess: { [weak self] lastBlockHeight in
                    self?.delegate?.didUpdate(lastBlockHeight: lastBlockHeight)
                    self?.fetchBalance()
                },
                onError: { [weak self] error in
                    self?.onFailSync(error: error)
                }
        )
    }

    private func fetchBalance() {
        send(
                rpc: GetBalanceJsonRpc(address: address, defaultBlockParameter: .latest),
                onSuccess: { [weak self] balance in
                    self?.delegate?.didUpdate(balance: balance)
                    self?.syncState = .synced
                },
                onError: { [weak self] error in
                    self?.onFailSync(error: error)
                }
        )
    }

    private func subscribeToNewHeads() {
        subscribe(
                subscription: NewHeadsRpcSubscription(),
                onSuccess: { [weak self] in
                    self?.isSubscribedToNewHeads = true
                },
                onError: { [weak self] error in
                    self?.onFailSync(error: error)
                },
                successHandler: { [weak self] header in
                    self?.delegate?.didUpdate(lastBlockLogsBloom: header.logsBloom)
                    self?.delegate?.didUpdate(lastBlockHeight: header.number)
                    self?.fetchBalance()
                },
                errorHandler: { [weak self] error in
                    self?.logger?.error("NewHeads Handle Failed: \(error)")
                }
        )
    }

    private func onFailSync(error: Error) {
        syncState = .notSynced(error: error)
//        socket.disconnect()
    }

}

extension WebSocketRpcSyncer: IWebSocketDelegate {

    func didUpdate(state: WebSocketState) {
        if case .notSynced(let error) = syncState, let syncError = error as? Kit.SyncError, syncError == .notStarted {
            // do not react to web socket state if syncer was stopped
            return
        }

        switch state {
        case .connecting:
            syncState = .syncing(progress: nil)
        case .connected:
            fetchLastBlockHeight()
            subscribeToNewHeads()
        case .disconnected(let error):
            queue.async { [weak self] in
                self?.rpcHandlers = [:]
                self?.subscriptionHandlers = [:]
            }

            isSubscribedToNewHeads = false
            syncState = .notSynced(error: error)
        }
    }

    func didReceive(data: Data) {
        queue.async { [weak self] in
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: data)

                if let rpcResponse = JsonRpcResponse.response(jsonObject: jsonObject) {
                    try self?.handle(rpcResponse: rpcResponse)
                } else if let subscriptionResponse = try? RpcSubscriptionResponse(JSONObject: jsonObject) {
                    try self?.handle(subscriptionResponse: subscriptionResponse)
                } else {
                    throw ParseError.invalidResponse(jsonObject: jsonObject)
                }
            } catch {
                self?.logger?.error("Handle Failed: \(error)")
            }
        }
    }

}

extension WebSocketRpcSyncer: IRpcSyncer {

    var source: String {
        "WebSocket \(socket.source)"
    }

    func start() {
        syncState = .syncing(progress: nil)

        socket.start()
    }

    func stop() {
        syncState = .notSynced(error: Kit.SyncError.notStarted)

        socket.stop()
    }

    func refresh() {
        // no need to refresh socket
    }

    func single<T>(rpc: JsonRpc<T>) -> Single<T> {
        Single<T>.create { [weak self] observer in
            self?.send(
                    rpc: rpc,
                    onSuccess: { value in
                        observer(.success(value))
                    },
                    onError: { error in
                        observer(.error(error))
                    }
            )

            return Disposables.create()
        }
    }

}

extension WebSocketRpcSyncer {

    enum ParseError: Error {
        case invalidResponse(jsonObject: Any)
    }

}

extension WebSocketRpcSyncer {

    static func instance(address: Address, socket: IWebSocket, logger: Logger? = nil) -> WebSocketRpcSyncer {
        let syncer = WebSocketRpcSyncer(address: address, socket: socket, logger: logger)
        socket.delegate = syncer
        return syncer
    }

}
