import Foundation

class PingMessage: IMessage {

    static let payload = Data(bytes: [UInt8(0xc0)])

    required init?(data: Data) {
    }

    func encoded() -> Data {
        return PingMessage.payload
    }

    func toString() -> String {
        return "PING"
    }

}
