import RxSwift
import Starscream
import HsToolKit

class InfuraWebSocket {
    static let unexpectedDisconnectErrorDomain = "NSPOSIXErrorDomain"
    static let unexpectedDisconnectErrorCode = 57

    private var disposeBag = DisposeBag()

    weak var delegate: IWebSocketDelegate?

    private var logger: Logger?

    private let queue = DispatchQueue(label: "io.horizontal-systems.ethereum-kit.infura-web-socket", qos: .userInitiated)
    private let reachabilityManager: IReachabilityManager
    private var isStarted = false

    private let socket: WebSocket
    private var state: WebSocketState = .disconnected(error: WebSocketState.DisconnectError.notStarted) {
        didSet {
            delegate?.didUpdate(state: state)
        }
    }
    private var mustReconnect = false

    init(domain: String, projectId: String, projectSecret: String?, reachabilityManager: IReachabilityManager, logger: Logger? = nil) {
        self.reachabilityManager = reachabilityManager
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

        reachabilityManager.reachabilityObservable
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] _ in
                    if reachabilityManager.isReachable {
                        self?.reconnect()
                    }
                })
                .disposed(by: disposeBag)
        
        NotificationCenter.default.addObserver(self, selector: #selector(appCameToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    @objc func appCameToForeground() {
        reconnect()
    }
    
    private func connect() {
        guard case .disconnected = state else {
            return
        }
        state = .connecting
        
        socket.connect()
        mustReconnect = false
    }

    private func reconnect() {
        guard isStarted else {
            return
        }
        
        if case .disconnected = state {
            connect()
        } else {
            mustReconnect = true
        }
    }

}

extension InfuraWebSocket: WebSocketDelegate {

    public func websocketDidConnect(socket: WebSocketClient) {
        logger?.debug("WebSocket is connected: \(socket)")

        state = .connected
    }

    public func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        logger?.debug("WebSocket is disconnected: \(error?.localizedDescription ?? "Unknown error")")

        state = .disconnected(error: error ?? WebSocketState.DisconnectError.socketDisconnected(reason: "Unknown reason"))
        
        if mustReconnect {
            reconnect()
        }
    }

    public func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        logger?.debug("WebSocket Received text: \(text)")

        if let data = text.data(using: .utf8) {
            delegate?.didReceive(data: data)
        } else {
            // todo: handle invalid message
        }
    }

    public func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        logger?.debug("WebSocket Received data: \(data.count)")
    }

}

extension InfuraWebSocket: IWebSocket {

    var source: String {
        "Infura"
    }

    func start() {
        isStarted = true
        connect()
    }

    func stop() {
        isStarted = false
        socket.disconnect()
    }

    func send(data: Data) throws {
        guard case .connected = state else {
            throw WebSocketState.StateError.notConnected
        }

        socket.write(data: data)
    }

}
