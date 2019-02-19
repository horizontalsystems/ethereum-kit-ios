import Foundation

class FramesMessageConverter: IFramesMessageConverter {

    static let devP2PGreatestMessageCode = 0x10

    var packetTypesMap: [Int: IMessage.Type] = [
        0x00: HelloMessage.self,
        0x01: DisconnectMessage.self,
        0x02: PingMessage.self,
        0x03: PongMessage.self
    ]

    func register(packetTypesMap: [Int: IMessage.Type]) {
        for (packetType, messageClass) in packetTypesMap {
            self.packetTypesMap[FramesMessageConverter.devP2PGreatestMessageCode + packetType] = messageClass
        }
    }

    func convertToMessage(frames: [Frame]) -> IMessage? {
        let frame = frames[0]
        let message: IMessage?

        guard let messageClass = packetTypesMap[frame.type] else {
            return nil
        }

        return messageClass.init(data: frame.payload)
    }

    func convertToFrames(message: IMessage) -> [Frame] {
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

