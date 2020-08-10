import HsToolKit

class DevP2PPeer {
    weak var delegate: IDevP2PPeerDelegate?

    private let devP2PConnection: IDevP2PConnection
    private let capabilityHelper: ICapabilityHelper
    private let myCapabilities: [Capability]
    private let myNodeId: Data
    private let port: Int
    private let logger: Logger?

    init(devP2PConnection: IDevP2PConnection, capabilityHelper: ICapabilityHelper, myCapabilities: [Capability], myNodeId: Data, port: Int, logger: Logger? = nil) {
        self.devP2PConnection = devP2PConnection
        self.capabilityHelper = capabilityHelper
        self.myCapabilities = myCapabilities
        self.myNodeId = myNodeId
        self.port = port
        self.logger = logger
    }

    private func handle(message: IInMessage) throws {
        switch message {
        case let message as HelloMessage: try handle(message: message)
        case let message as DisconnectMessage: try handle(message: message)
        case let message as PingMessage: handle(message: message)
        case let message as PongMessage: handle(message: message)
        default: delegate?.didReceive(message: message)
        }
    }

    private func handle(message: HelloMessage) throws {
        let sharedCapabilities = capabilityHelper.sharedCapabilities(myCapabilities: myCapabilities, nodeCapabilities: message.capabilities)

        guard !sharedCapabilities.isEmpty else {
            throw CapabilityError.noSharedCapabilities
        }

        devP2PConnection.register(sharedCapabilities: sharedCapabilities)
        delegate?.didConnect()
    }

    private func handle(message: DisconnectMessage) throws {
        throw DisconnectError.disconnectMessageReceived
    }

    private func handle(message: PingMessage) {
        let pongMessage = PongMessage()
        send(message: pongMessage)
    }

    private func handle(message: PongMessage) {
        // no actions required
    }

    private func log(_ message: String, level: Logger.Level = .debug) {
        logger?.log(level: level, message: message, context: [logName])
    }

}

extension DevP2PPeer: IDevP2PPeer {

    func connect() {
        devP2PConnection.connect()
    }

    func disconnect(error: Error? = nil) {
        devP2PConnection.disconnect(error: error)
    }

    func send(message: IOutMessage) {
        devP2PConnection.send(message: message)
    }

    var logName: String {
        return devP2PConnection.logName
    }

}

extension DevP2PPeer: IDevP2PConnectionDelegate {

    func didConnect() {
        let helloMessage = HelloMessage(nodeId: myNodeId, port: port, capabilities: myCapabilities)
        send(message: helloMessage)
    }

    func didDisconnect(error: Error?) {
        delegate?.didDisconnect(error: error)
    }

    func didReceive(message: IInMessage) {
        log("<<< \(message.toString())")

        do {
            try handle(message: message)
        } catch {
            disconnect(error: error)
        }
    }

}

extension DevP2PPeer {

    static func instance(key: ECKey, node: Node, capabilities: [Capability], logger: Logger? = nil) -> DevP2PPeer {
        let nodeId = key.publicKeyPoint.x + key.publicKeyPoint.y
        let port = 30303

        let devP2PConnection = DevP2PConnection.instance(connectionKey: key, node: node, logger: logger)
        let peer = DevP2PPeer(devP2PConnection: devP2PConnection, capabilityHelper: CapabilityHelper(), myCapabilities: capabilities, myNodeId: nodeId, port: port, logger: logger)

        devP2PConnection.delegate = peer

        return peer
    }

}

extension DevP2PPeer {

    enum DisconnectError: Error {
        case disconnectMessageReceived
    }

    enum CapabilityError: Error {
        case noSharedCapabilities
    }

}
