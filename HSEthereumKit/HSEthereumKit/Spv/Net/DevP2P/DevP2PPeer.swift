class DevP2PPeer {
    weak var delegate: IDevP2PPeerDelegate?

    private let connection: IConnection
    private let key: ECKey
    private let capability: Capability
    private let messageFactory: IMessageFactory
    private let logger: Logger?

    init(connection: IConnection, key: ECKey, capability: Capability, messageFactory: IMessageFactory, logger: Logger? = nil) {
        self.connection = connection
        self.key = key
        self.capability = capability
        self.messageFactory = messageFactory
        self.logger = logger
    }

    private func handle(message: IHelloMessage) {
        do {
            try validatePeer(helloMessage: message)
            connection.register(capabilities: [capability])
            delegate?.didEstablishConnection()
        } catch {
            disconnect(error: error)
        }

    }

    private func handle(message: IDisconnectMessage) {
        disconnect(error: DevP2PPeerError.disconnectMessageReceived)
    }

    private func handle(message: IPingMessage) {
        let pongMessage = messageFactory.pongMessage()
        connection.send(message: pongMessage)
    }

    private func handle(message: IPongMessage) {
    }

    private func validatePeer(helloMessage: IHelloMessage) throws {
        guard helloMessage.capabilities.contains(capability) else {
            throw DevP2PPeerError.peerDoesNotSupportCapability
        }
    }

}

extension DevP2PPeer {

    func connect() {
        connection.connect()
    }

    func disconnect(error: Error? = nil) {
        connection.disconnect(error: error)
    }

    func send(message: IMessage) {
        connection.send(message: message)
    }

}

extension DevP2PPeer: IConnectionDelegate {

    func didEstablishConnection() {
        let helloMessage = messageFactory.helloMessage(key: key, capabilities: [capability])
        connection.send(message: helloMessage)
    }

    func didDisconnect(error: Error?) {
        delegate?.didDisconnect(error: error)
    }

    func didReceive(message: IMessage) {
        logger?.verbose("<<< \(message.toString())")

        switch message {
        case let message as IHelloMessage: handle(message: message)
        case let message as IDisconnectMessage: handle(message: message)
        case let message as IPingMessage: handle(message: message)
        case let message as IPongMessage: handle(message: message)
        default: delegate?.didReceive(message: message)
        }
    }

}

extension DevP2PPeer {

    static func instance(key: ECKey, node: Node, capability: Capability, logger: Logger? = nil) -> DevP2PPeer {
        let connection: IConnection = Connection(connectionKey: key, node: node, logger: logger)
        let peer = DevP2PPeer(connection: connection, key: key, capability: capability, messageFactory: MessageFactory(), logger: logger)

        connection.delegate = peer

        return peer
    }

}

extension DevP2PPeer {

    enum DevP2PPeerError: Error {
        case peerDoesNotSupportCapability
        case disconnectMessageReceived
    }

}
