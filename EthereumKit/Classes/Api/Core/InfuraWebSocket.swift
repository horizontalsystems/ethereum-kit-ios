import Starscream
import BigInt
import HsToolKit

class InfuraWebSocket {
    typealias RpcHandler = (Any) -> ()

    weak var delegate: IWebSocketDelegate?

    private var logger: Logger?

    private let queue = DispatchQueue(label: "io.horizontal-systems.ethereum-kit.web-socket-syncer", qos: .userInitiated)

    private let socket: WebSocket
    private var isConnected = false

    private var currentRpcId = 0
    private var rpcHandlers = [Int: RpcHandler]()
    private var subscriptionHandlers = [Int: RpcHandler]()

    init(domain: String, projectId: String, projectSecret: String?, logger: Logger? = nil) {
        self.logger = logger

        var request = URLRequest(url: URL(string: "wss://\(domain)/ws/v3/\(projectId)")!)
        request.timeoutInterval = 5

        if let projectSecret = projectSecret {
            let auth = Data(":\(projectSecret)".utf8).base64EncodedString()
            request.setValue("Basic \(auth)", forHTTPHeaderField: "Authorization")
        }

        socket = WebSocket(request: request)
        socket.delegate = self
        socket.callbackQueue = queue
    }

    private var nextRpcId: Int {
        currentRpcId += 1
        return currentRpcId
    }

    private func send<T>(rpc: JsonRpc<T>, handler: @escaping RpcHandler) throws {
        let rpcId = nextRpcId

        let parameters = rpc.parameters(id: rpcId)

        guard isConnected else {
            logger?.error("Send RPC Failed: Not Connected: \(parameters)")
            throw SocketError.notConnected
        }

        let data = try JSONSerialization.data(withJSONObject: parameters)

        rpcHandlers[rpcId] = handler

        socket.write(data: data)

        logger?.debug("Send RPC: \(parameters)")
    }

    private func handle(string: String) {
        do {
            guard let data = string.data(using: .utf8) else {
                throw ParseError.invalidDataFromString(value: string)
            }

            let jsonObject = try JSONSerialization.jsonObject(with: data)

            guard let response = jsonObject as? [String: Any] else {
                throw ParseError.invalidJson(value: jsonObject)
            }

            if let rpcId = response["id"] as? Int {
                try handleRpc(response: response, rpcId: rpcId)
            } else if response["method"] as? String == "eth_subscription" {
                try handleSubscription(response: response)
            } else {
                throw ParseError.unknownResponse(response: response)
            }
        } catch {
            logger?.error("Handle Failed: \(error)")
        }
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

    private func onDisconnect() {
        isConnected = false
        rpcHandlers = [:]
        subscriptionHandlers = [:]
    }

}

extension InfuraWebSocket: WebSocketDelegate {

    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(let headers):
            logger?.debug("WebSocket is connected: \(headers)")

            isConnected = true

            delegate?.didConnect()

        case .disconnected(let reason, let code):
            logger?.debug("WebSocket is disconnected: \(reason) with code: \(code)")

            onDisconnect()
            delegate?.didDisconnect(error: SocketError.disconnected(reason: reason))

        case .text(let string):
            logger?.debug("WebSocket Received text: \(string)")

            handle(string: string)

        case .binary(let data):
            logger?.debug("WebSocket Received data: \(data.count)")

        case .ping(_):
            break

        case .pong(_):
            break

        case .viabilityChanged(_):
            break

        case .reconnectSuggested(_):
            break

        case .cancelled:
            logger?.debug("WebSocket Cancelled")

            onDisconnect()

        case .error(let error):
            logger?.error("WebSocket Error: \(error?.localizedDescription ?? "unknown error")")

            onDisconnect()
            delegate?.didDisconnect(error: SocketError.error(error: error))
        }
    }

}

extension InfuraWebSocket: IWebSocket {

    func connect() {
        socket.connect()
    }

    func disconnect(error: Error) {
        socket.disconnect()
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

}

extension InfuraWebSocket {

    enum SocketError: Error {
        case notConnected
        case disconnected(reason: String)
        case error(error: Error?)
    }

    enum ParseError: Error {
        case invalidDataFromString(value: String)
        case invalidJson(value: Any)
        case unknownResponse(response: [String: Any])
        case noResult(response: [String: Any])
        case noParams(response: [String: Any])
        case noSubscriptionId(params: [String: Any])
    }

}
