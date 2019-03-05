import Foundation

class FrameHandler: IFrameHandler {

    enum FrameHandlerError: Error {
        case unknownMessageType
        case invalidPayload
    }

    static let devP2PMaxMessageCode = 0x10
    static let devP2PPacketTypesMap: [Int: IMessage.Type] = [
        0x00: HelloMessage.self,
        0x01: DisconnectMessage.self,
        0x02: PingMessage.self,
        0x03: PongMessage.self
    ]

    private var frames = [Frame]()
    private var packetTypesMap: [Int: IMessage.Type] = FrameHandler.devP2PPacketTypesMap

    func register(capabilities: [Capability]) {
        self.packetTypesMap = FrameHandler.devP2PPacketTypesMap
        var offset = FrameHandler.devP2PMaxMessageCode

        let sortedCapabilities = capabilities.sorted(by: { $0.name < $1.name || ($0.name == $1.name && $0.version < $1.version)  })
        for capability in sortedCapabilities {
            for (packetType, messageClass) in capability.packetTypesMap {
                self.packetTypesMap[offset + packetType] = messageClass
            }

            offset = self.packetTypesMap.keys.max() ?? offset
        }
    }

    func add(frame: Frame) {
        self.frames.append(frame)
    }

    func getMessage() throws -> IMessage? {
        guard !frames.isEmpty else {
            return nil
        }

        let frame = frames.removeFirst()

        guard let messageClass = packetTypesMap[frame.type] else {
            throw FrameHandlerError.unknownMessageType
        }

        do {
            return try messageClass.init(data: frame.payload)
        } catch {
            throw FrameHandlerError.invalidPayload
        }
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
