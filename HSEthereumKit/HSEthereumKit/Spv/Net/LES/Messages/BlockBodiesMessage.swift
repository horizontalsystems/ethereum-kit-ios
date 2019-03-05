import Foundation

class BlockBodiesMessage: IMessage {

    var requestId = 0
    var bv: BInt = 0
    var receipts = [[Data]]()

    required init(data: Data) throws {
        let rlpList = try RLP.decode(input: data).listValue()

        guard rlpList.count > 0 else {
            throw MessageDecodeError.notEnoughFields
        }
    }

    func encoded() -> Data {
        return Data()
    }

    func toString() -> String {
        return "BLOCK_BODIES []"
    }

}
