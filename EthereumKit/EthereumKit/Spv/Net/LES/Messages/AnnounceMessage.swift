import BigInt

class AnnounceMessage: IInMessage {
    let blockHash: Data
    let blockTotalDifficulty: BigUInt
    let blockHeight: Int
    let reorganizationDepth: Int

    init(blockHash: Data, blockTotalDifficulty: BigUInt, blockHeight: Int, reorganizationDepth: Int) {
        self.blockHash = blockHash
        self.blockTotalDifficulty = blockTotalDifficulty
        self.blockHeight = blockHeight
        self.reorganizationDepth = reorganizationDepth
    }

    required init(data: Data) throws  {
        let rlpList = try RLP.decode(input: data).listValue()

        guard rlpList.count >= 4 else {
            throw MessageDecodeError.notEnoughFields
        }

        blockHash = rlpList[0].dataValue
        blockHeight = try rlpList[1].intValue()
        blockTotalDifficulty = try rlpList[2].bigIntValue()
        reorganizationDepth = try rlpList[3].intValue()
    }

    func encoded() -> Data {
        return Data()
    }

    func toString() -> String {
        return "ANNOUNCE [blockHash: \(blockHash.toHexString()); blockTotalDifficulty: \(blockTotalDifficulty); blockHeight: \(blockHeight); " +
                "reorganizationDepth: \(reorganizationDepth)]"
    }

}
