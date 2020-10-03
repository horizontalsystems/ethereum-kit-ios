import Starscream
import HsToolKit

class InfuraWebSocket {
    weak var delegate: IWebSocketDelegate?

    private var logger: Logger?

    private let queue = DispatchQueue(label: "io.horizontal-systems.ethereum-kit.infura-web-socket", qos: .userInitiated)

    private let socket: WebSocket
    private var state: WebSocketState = .disconnected(error: WebSocketState.DisconnectError.notStarted) {
        didSet {
            delegate?.didUpdate(state: state)
        }
    }

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

}

extension InfuraWebSocket: WebSocketDelegate {

    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(let headers):
            logger?.debug("WebSocket is connected: \(headers)")

            state = .connected

        case .disconnected(let reason, let code):
            logger?.debug("WebSocket is disconnected: \(reason) with code: \(code)")

            state = .disconnected(error: WebSocketState.DisconnectError.socketDisconnected(reason: reason))

        case .text(let string):
            logger?.debug("WebSocket Received text: \(string)")

            if let data = string.data(using: .utf8) {
                delegate?.didReceive(data: data)
            } else {
                // todo: handle invalid message
            }

        case .binary(let data):
            logger?.debug("WebSocket Received data: \(data.count)")

        case .ping(_):
            break

        case .pong(_):
            break

        case .viabilityChanged(let viable):
            if viable {
                if case .connecting = state {} else {
                    start()
                }
            } else {
                stop()
            }

        case .reconnectSuggested(let isBetter):
            if isBetter {
                stop()
                start()
            }

        case .cancelled:
            logger?.debug("WebSocket Cancelled")

            state = .disconnected(error: WebSocketState.DisconnectError.socketDisconnected(reason: "Disconnected from server end"))

        case .error(let error):
            logger?.error("WebSocket Error: \(error?.localizedDescription ?? "unknown error")")

        }
    }

}

extension InfuraWebSocket: IWebSocket {

    var source: String {
        "Infura"
    }

    func start() {
        state = .connecting

        socket.connect()
    }

    func stop() {
        socket.disconnect()
    }

    func send(data: Data) throws {
        guard case .connected = state else {
            throw WebSocketState.StateError.notConnected
        }

        socket.write(data: data)
    }

}
