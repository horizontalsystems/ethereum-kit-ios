import RxSwift
import HsToolKit

class RpcWebSocket {
    weak var delegate: IRpcWebSocketDelegate?

    private let socket: IWebSocket
    private var logger: Logger?

    init(socket: IWebSocket, logger: Logger? = nil) {
        self.socket = socket
        self.logger = logger
    }

}

extension RpcWebSocket: IRpcWebSocket {

    var source: String {
        socket.source
    }

    func start() {
        socket.start()
    }

    func stop() {
        socket.stop()
    }

    func send<T>(rpc: JsonRpc<T>, rpcId: Int) throws {
        let parameters = rpc.parameters(id: rpcId)
        let data = try JSONSerialization.data(withJSONObject: parameters)

        try socket.send(data: data)

        logger?.debug("Send RPC: \(String(data: data, encoding: .utf8) ?? "nil")")
    }

}

extension RpcWebSocket: IWebSocketDelegate {

    func didUpdate(state: WebSocketState) {
        delegate?.didUpdate(state: state)
    }

    func didReceive(data: Data) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)

            if let rpcResponse = JsonRpcResponse.response(jsonObject: jsonObject) {
                self.delegate?.didReceive(rpcResponse: rpcResponse)
            } else if let subscriptionResponse = try? RpcSubscriptionResponse(JSONObject: jsonObject) {
                self.delegate?.didReceive(subscriptionResponse: subscriptionResponse)
            } else {
                throw ParseError.invalidResponse(jsonObject: jsonObject)
            }
        } catch {
            logger?.error("Handle Failed: \(error)")
        }
    }

}

extension RpcWebSocket {

    enum ParseError: Error {
        case invalidResponse(jsonObject: Any)
    }

}
