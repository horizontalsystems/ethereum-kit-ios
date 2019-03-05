import Foundation

class AnnounceMessage: IMessage {

    var bestBlockTotalDifficulty = Data()
    var bestBlockHash = Data()
    var bestBlockHeight = BInt(0)
    var reorganizationDepth = BInt(0)

    required init(data: Data) throws  {
        let rlpList = try RLP.decode(input: data).listValue()

        guard rlpList.count > 0 else {
            throw MessageDecodeError.notEnoughFields
        }
    }

    func encoded() -> Data {
        return Data()
    }

    func toString() -> String {
        return "ANNOUNCE []"
    }

}
