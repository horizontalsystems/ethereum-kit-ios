import Foundation

class Frame {

    let type: Int
    let payloadSize: Int
    let payload: Data

    var contextId = -1
    var allFramesTotalSize = -1
    var size = 0

    init(message: IMessage) {
        self.type = message.code
        self.payload = message.encoded()
        self.payloadSize = payload.count
    }

    init(type: Int, payload: Data, size: Int, contextId: Int, allFramesTotalSize: Int) {
        self.type = type
        self.payload = payload
        self.payloadSize = payload.count
        self.size = size
        self.contextId = contextId
        self.allFramesTotalSize = allFramesTotalSize
    }

    static func framesToMessage(frames: [Frame]) -> IMessage? {
        guard frames.count > 0 else {
            return nil
        }

        let frame = frames[0]
        let message: IMessage?

        switch frame.type {
        case HelloMessage.code: message = HelloMessage(data: frame.payload)
        case PingMessage.code: message = PingMessage(data: frame.payload)
        case PongMessage.code: message = PongMessage(data: frame.payload)
        case DisconnectMessage.code: message = DisconnectMessage(data: frame.payload)
        case StatusMessage.code: message = StatusMessage(data: frame.payload)
        default: message = nil
        }

        return message
    }

}
