import Foundation

class BlockHeadersMessage: IMessage {

    static let code = 0x13
    var code: Int { return BlockHeadersMessage.code }

    var requestId: Int
    var bv: Int
    var headers: [BlockHeader]

    init(data: Data) {
        let rlp = try! RLP.decode(input: data)

        self.requestId = rlp.listValue[0].intValue
        self.bv = rlp.listValue[1].intValue

        var headers = [BlockHeader]()

        for rlpHeader in rlp.listValue[2].listValue {
            headers.append(BlockHeader(rlp: rlpHeader))
        }

        self.headers = headers
    }

    func encoded() -> Data {
        return Data()
    }

    func toString() -> String {
        return "HEADERS [requestId: \(requestId); bv: \(bv); headers: [\(headers.map{ $0.toString() }.joined(separator: ","))]]"
    }

}
