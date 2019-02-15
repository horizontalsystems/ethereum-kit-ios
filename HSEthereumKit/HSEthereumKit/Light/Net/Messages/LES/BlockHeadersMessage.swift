import Foundation

class BlockHeadersMessage: IMessage {

    static let code = 0x13
    var code: Int { return BlockHeadersMessage.code }

    var requestId = 0
    var bv = 0
 
    var headers = [[Data]]() // In format specified in Ethereum specification

    init(data: Data) {
        print(data.toHexString())
        print()
    }

    func encoded() -> Data {
        return Data()
    }

    func toString() -> String {
        return "HEADERS []"
    }

}
