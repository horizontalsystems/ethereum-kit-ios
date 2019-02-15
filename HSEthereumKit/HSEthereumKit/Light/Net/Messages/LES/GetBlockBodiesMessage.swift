import Foundation

class GetBlockBodiesMessage: IMessage {

    static let code = 0x14
    var code: Int { return GetBlockBodiesMessage.code }

    var requestId = 0
    var transactions = [[Data]]() // In format described in Ethereum specification
    var receipts = [[Data]]() // In format described in Ethereum specification

    init(data: Data) {
    }

    func encoded() -> Data {
        return Data()
    }

    func toString() -> String {
        return "GET_BLOCK_BODIES []"
    }

}
