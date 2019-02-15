import Foundation

class AnnounceMessage: IMessage {

    static let code = 0x11
    var code: Int { return AnnounceMessage.code }

    var bestBlockTotalDifficulty = Data()
    var bestBlockHash = Data()
    var bestBlockHeight = BInt(0)
    var reorganizationDepth = BInt(0)

    init(data: Data) {
    }

    func encoded() -> Data {
        return Data()
    }

    func toString() -> String {
        return "ANNOUNCE []"
    }

}
