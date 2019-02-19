import Foundation

class GetBlockBodiesMessage: IMessage {

    var requestId = 0
    var transactions = [[Data]]() // In format described in Ethereum specification
    var receipts = [[Data]]() // In format described in Ethereum specification

    required init?(data: Data) {
        let rlp = RLP.decode(input: data)

        guard rlp.isList() && rlp.listValue.count > 0 else {
            return nil
        }
    }

    func encoded() -> Data {
        return Data()
    }

    func toString() -> String {
        return "GET_BLOCK_BODIES []"
    }

}
