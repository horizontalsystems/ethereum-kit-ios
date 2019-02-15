import Foundation

class BlockBodiesMessage: IMessage {

    static let code = 0x15
    var code: Int { return BlockBodiesMessage.code }

    var requestId = 0
    var bv = 0
  
    var receipts = [[Data]]()

    init(data: Data) {
    }

    func encoded() -> Data {
        return Data()
    }

    func toString() -> String {
        return "BLOCK_BODIES []"
    }

}
