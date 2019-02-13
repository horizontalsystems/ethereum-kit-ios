import Foundation

class PingMessage : IMessage {

    static let code = 0x02
    static let payload = Data(bytes: [UInt8(0xc0)])
    var code: Int { return PingMessage.code }

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
