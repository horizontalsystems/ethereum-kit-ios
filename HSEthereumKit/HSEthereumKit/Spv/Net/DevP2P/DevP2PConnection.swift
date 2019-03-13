class DevP2PConnection {
    private static let devP2PMaxMessageCode = 0x10
    private static let devP2PPacketTypesMap: [Int: IMessage.Type] = [
        0x00: HelloMessage.self,
        0x01: DisconnectMessage.self,
        0x02: PingMessage.self,
        0x03: PongMessage.self
    ]

    weak var delegate: IDevP2PConnectionDelegate?

    private let frameConnection: IFrameConnection
    private let logger: Logger?
    private var packetTypesMap: [Int: IMessage.Type] = DevP2PConnection.devP2PPacketTypesMap

    let myCapabilities: [Capability]

    init(frameConnection: IFrameConnection, myCapabilities: [Capability], logger: Logger? = nil) {
        self.frameConnection = frameConnection
        self.myCapabilities = myCapabilities
        self.logger = logger
    }
}

extension DevP2PConnection: IDevP2PConnection {

    func register(nodeCapabilities: [Capability]) throws {
        var sharedCapabilities = [Capability]()

        for myCapability in myCapabilities {
            if nodeCapabilities.contains(myCapability) {
                sharedCapabilities.append(myCapability)
            }
        }

        guard !sharedCapabilities.isEmpty else {
            throw CapabilityError.noCommonCapabilities
        }

        packetTypesMap = DevP2PConnection.devP2PPacketTypesMap
        var offset = DevP2PConnection.devP2PMaxMessageCode

        let sortedCapabilities = sharedCapabilities.sorted(by: { $0.name < $1.name || ($0.name == $1.name && $0.version < $1.version)  })
        for capability in sortedCapabilities {
            for (packetType, messageClass) in capability.packetTypesMap {
                packetTypesMap[offset + packetType] = messageClass
            }

            offset = packetTypesMap.keys.max() ?? offset
        }
    }

    func connect() {
        frameConnection.connect()
    }

    func disconnect(error: Error?) {
        frameConnection.disconnect(error: error)
    }

    func send(message: IOutMessage) {
        for (packetType, messageClass) in packetTypesMap {
            if (messageClass == type(of: message)) {
                logger?.verbose(">>> \(message.toString())")

                frameConnection.send(packetType: packetType, payload: message.encoded())
                break
            }
        }
    }

}

extension DevP2PConnection: IFrameConnectionDelegate {

    func didConnect() {
        delegate?.didConnect()
    }

    func didDisconnect(error: Error?) {
        delegate?.didDisconnect(error: error)
    }

    func didReceive(packetType: Int, payload: Data) {
        guard let messageClass = packetTypesMap[packetType] else {
            disconnect(error: DeserializeError.unknownMessageType)
            return
        }

        guard let inMessageClass = messageClass as? IInMessage.Type else {
            disconnect(error: DeserializeError.inMessageNotSupported)
            return
        }

        do {
            let message = try inMessageClass.init(data: payload)
            delegate?.didReceive(message: message)
        } catch {
            disconnect(error: DeserializeError.invalidPayload)
        }
    }

}

extension DevP2PConnection {

    enum DeserializeError: Error {
        case unknownMessageType
        case inMessageNotSupported
        case invalidPayload
    }

    enum CapabilityError: Error {
        case noCommonCapabilities
    }

}

extension DevP2PConnection {

    static func instance(myCapabilities: [Capability], connectionKey: ECKey, node: Node, logger: Logger? = nil) -> DevP2PConnection {
        let frameConnection = FrameConnection.instance(connectionKey: connectionKey, node: node, logger: logger)
        let devP2PConnection = DevP2PConnection(frameConnection: frameConnection, myCapabilities: myCapabilities, logger: logger)

        frameConnection.delegate = devP2PConnection

        return devP2PConnection
    }

}
