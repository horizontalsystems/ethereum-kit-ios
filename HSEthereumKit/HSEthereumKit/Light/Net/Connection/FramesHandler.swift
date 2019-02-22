import Foundation

class FrameHandler: IFrameHandler {

    enum FrameHandlerError: Error {
        case unknownMessageType
        case invalidPayload
    }

    static let devP2PGreatestMessageCode = 0x10
    static let devP2PPacketTypesMap: [Int: IMessage.Type] = [
        0x00: HelloMessage.self,
        0x01: DisconnectMessage.self,
        0x02: PingMessage.self,
        0x03: PongMessage.self
    ]

    var packetTypesMap: [Int: IMessage.Type] = FrameHandler.devP2PPacketTypesMap
    var frames = [Frame]()
    var capabilities: [Capability] = []

    func register(capability: Capability) {
        self.packetTypesMap = FrameHandler.devP2PPacketTypesMap

        capabilities.append(capability)
        let sortedCapabilities = capabilities.sorted(by: { $0.name < $1.name || ($0.name == $1.name && $0.version < $1.version)  })

        var offsetMessageCode = FrameHandler.devP2PGreatestMessageCode
        for capability in sortedCapabilities {
            for (packetType, messageClass) in capability.packetTypesMap {
                self.packetTypesMap[offsetMessageCode + packetType] = messageClass
            }

            if let offset = self.packetTypesMap.keys.sorted().last {
                offsetMessageCode = offset
            }
        }
    }

    func addFrames(frames: [Frame]) {
        self.frames.append(contentsOf: frames)
    }

    func getMessage() throws -> IMessage? {
        guard !frames.isEmpty else {
            return nil
        }

        let frame = frames.removeFirst()

        guard let messageClass = packetTypesMap[frame.type] else {
            throw FrameHandlerError.unknownMessageType
        }

        guard let message = messageClass.init(data: frame.payload) else {
            throw FrameHandlerError.invalidPayload
        }

        return message
    }

    func getFrames(from message: IMessage) -> [Frame] {
        var frames = [Frame]()

        for (packetType, messageClass) in packetTypesMap {
            if (messageClass == type(of: message)) {
                frames.append(Frame(type: packetType, payload: message.encoded(), contextId: -1, allFramesTotalSize: -1))
                break
            }
        }

        return frames
    }
}

