import RxSwift
import Starscream
import BigInt
import HsToolKit

class WebSocketRpcSyncer {
    typealias RpcHandler = (Any) -> ()

    weak var delegate: IRpcSyncerDelegate?

    private let address: Address
    private let socket: IWebSocket
    private var logger: Logger?

    private var currentRpcId = 0
    private var rpcHandlers = [Int: RpcHandler]()
    private var subscriptionHandlers = [Int: RpcHandler]()

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
                try self?.send(rpc: rpc) { result in
                    do {
                        onSuccess(try rpc.parse(result: result))
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
                    self?.subscriptionHandlers[subscriptionId] = { result in
                        do {
                            successHandler(try subscription.parse(result: result))
                        } catch {
                            errorHandler(error)
                        }
                    }
                    onSuccess()
                },
                onError: onError
        )
    }

    private func handleRpc(response: [String: Any], rpcId: Int) throws {
        let handler = rpcHandlers.removeValue(forKey: rpcId)

        guard let result = response["result"] else {
            throw ParseError.noResult(response: response)
        }

        handler?(result)
    }

    private func handleSubscription(response: [String: Any]) throws {
        guard let params = response["params"] as? [String: Any] else {
            throw ParseError.noParams(response: response)
        }

        guard let subscriptionHex = params["subscription"] as? String, let subscriptionId = Int(subscriptionHex.stripHexPrefix(), radix: 16) else {
            throw ParseError.noSubscriptionId(params: params)
        }

        guard let result = params["result"] else {
            throw ParseError.noResult(response: response)
        }

        subscriptionHandlers[subscriptionId]?(result)
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

                guard let response = jsonObject as? [String: Any] else {
                    throw ParseError.invalidJson(value: jsonObject)
                }

                if let rpcId = response["id"] as? Int {
                    try self?.handleRpc(response: response, rpcId: rpcId)
                } else if response["method"] as? String == "eth_subscription" {
                    try self?.handleSubscription(response: response)
                } else {
                    throw ParseError.unknownResponse(response: response)
                }
            } catch {
                self?.logger?.error("Handle Failed: \(error)")
            }
        }
    }

}

extension WebSocketRpcSyncer: IRpcSyncer {

    var source: String {
        "WebSocket Infura"
    }

    func start() {
        socket.start()
    }

    func stop(error: Error) {
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
        case invalidJson(value: Any)
        case unknownResponse(response: [String: Any])
        case noResult(response: [String: Any])
        case noParams(response: [String: Any])
        case noSubscriptionId(params: [String: Any])
        case noBlockNumber(result: [String: Any])
    }

}

extension WebSocketRpcSyncer {

    static func instance(address: Address, socket: IWebSocket, logger: Logger? = nil) -> WebSocketRpcSyncer {
        let syncer = WebSocketRpcSyncer(address: address, socket: socket, logger: logger)
        socket.delegate = syncer
        return syncer
    }

}
