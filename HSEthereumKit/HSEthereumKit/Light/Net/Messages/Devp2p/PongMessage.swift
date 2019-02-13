import Foundation

class PongMessage : IMessage {

    static let code = 0x03
    static let payload = Data(bytes: [UInt8(0xc0)])
    var code: Int { return PongMessage.code }

    init() {
    }

    init(data: Data) {
    }

    func encoded() -> Data {
        return PingMessage.payload
    }

    func toString() -> String {
        return ""
    }

}
