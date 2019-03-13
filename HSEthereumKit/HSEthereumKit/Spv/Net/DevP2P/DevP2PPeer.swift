class DevP2PPeer {
    weak var delegate: IDevP2PPeerDelegate?

    private let devP2PConnection: IDevP2PConnection
    private let messageFactory: IMessageFactory
    private let key: ECKey
    private let logger: Logger?

    init(devP2PConnection: IDevP2PConnection, messageFactory: IMessageFactory, key: ECKey, logger: Logger? = nil) {
        self.devP2PConnection = devP2PConnection
        self.messageFactory = messageFactory
        self.key = key
        self.logger = logger
    }

    private func handle(message: HelloMessage) {
        do {
            try devP2PConnection.register(nodeCapabilities: message.capabilities)
            delegate?.didConnect()
        } catch {
            disconnect(error: error)
        }

    }

    private func handle(message: DisconnectMessage) {
        disconnect(error: DisconnectError.disconnectMessageReceived)
    }

    private func handle(message: PingMessage) {
        let pongMessage = messageFactory.pongMessage()
        send(message: pongMessage)
    }

    private func handle(message: PongMessage) {
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

}

extension DevP2PPeer: IDevP2PConnectionDelegate {

    func didConnect() {
        let helloMessage = messageFactory.helloMessage(key: key, capabilities: devP2PConnection.myCapabilities)
        send(message: helloMessage)
    }

    func didDisconnect(error: Error?) {
        delegate?.didDisconnect(error: error)
    }

    func didReceive(message: IInMessage) {
        logger?.verbose("<<< \(message.toString())")

        switch message {
        case let message as HelloMessage: handle(message: message)
        case let message as DisconnectMessage: handle(message: message)
        case let message as PingMessage: handle(message: message)
        case let message as PongMessage: handle(message: message)
        default: delegate?.didReceive(message: message)
        }
    }

}

extension DevP2PPeer {

    static func instance(key: ECKey, node: Node, capabilities: [Capability], logger: Logger? = nil) -> DevP2PPeer {
        let devP2PConnection = DevP2PConnection.instance(myCapabilities: capabilities, connectionKey: key, node: node, logger: logger)
        let peer = DevP2PPeer(devP2PConnection: devP2PConnection, messageFactory: MessageFactory(), key: key, logger: logger)

        devP2PConnection.delegate = peer

        return peer
    }

}

extension DevP2PPeer {

    enum DisconnectError: Error {
        case disconnectMessageReceived
    }

}
