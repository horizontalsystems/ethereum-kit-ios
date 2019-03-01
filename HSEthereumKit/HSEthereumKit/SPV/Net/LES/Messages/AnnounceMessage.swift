import Foundation

class AnnounceMessage: IMessage {

    var bestBlockTotalDifficulty = Data()
    var bestBlockHash = Data()
    var bestBlockHeight = BInt(0)
    var reorganizationDepth = BInt(0)

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
        return "ANNOUNCE []"
    }

}
