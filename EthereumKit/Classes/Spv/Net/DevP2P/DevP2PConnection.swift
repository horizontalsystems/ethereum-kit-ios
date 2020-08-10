import HsToolKit

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

    init(frameConnection: IFrameConnection, logger: Logger? = nil) {
        self.frameConnection = frameConnection
        self.logger = logger
    }

    private func handle(packetType: Int, payload: Data) throws {
        guard let messageClass = packetTypesMap[packetType] else {
            throw DeserializeError.unknownMessageType
        }

        guard let inMessageClass = messageClass as? IInMessage.Type else {
            throw DeserializeError.inMessageNotSupported
        }

        do {
            let message = try inMessageClass.init(data: payload)
            delegate?.didReceive(message: message)
        } catch {
            log("Could not create message \(inMessageClass): \(error)")
            throw DeserializeError.invalidPayload
        }

    }

    private func log(_ message: String, level: Logger.Level = .debug) {
        logger?.log(level: level, message: message, context: [logName])
    }

}

extension DevP2PConnection: IDevP2PConnection {

    func register(sharedCapabilities: [Capability]) {
        packetTypesMap = DevP2PConnection.devP2PPacketTypesMap
        var offset = DevP2PConnection.devP2PMaxMessageCode

        for capability in sharedCapabilities {
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
                log(">>> \(message.toString())")

                frameConnection.send(packetType: packetType, payload: message.encoded())
                break
            }
        }
    }

    var logName: String {
        return frameConnection.logName
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
        do {
            try handle(packetType: packetType, payload: payload)
        } catch {
            disconnect(error: error)
        }
    }

}

extension DevP2PConnection {

    enum DeserializeError: Error {
        case unknownMessageType
        case inMessageNotSupported
        case invalidPayload
    }

}

extension DevP2PConnection {

    static func instance(connectionKey: ECKey, node: Node, logger: Logger? = nil) -> DevP2PConnection {
        let frameConnection = FrameConnection.instance(connectionKey: connectionKey, node: node, logger: logger)
        let devP2PConnection = DevP2PConnection(frameConnection: frameConnection, logger: logger)

        frameConnection.delegate = devP2PConnection

        return devP2PConnection
    }

}
