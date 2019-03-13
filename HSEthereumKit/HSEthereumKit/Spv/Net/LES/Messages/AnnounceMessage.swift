class AnnounceMessage: IInMessage {
    let blockHash: Data
    let blockTotalDifficulty: BInt
    let blockHeight: BInt
    let reorganizationDepth: BInt

    init(blockHash: Data, blockTotalDifficulty: BInt, blockHeight: BInt, reorganizationDepth: BInt) {
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
        blockHeight = try rlpList[1].bIntValue()
        blockTotalDifficulty = try rlpList[2].bIntValue()
        reorganizationDepth = try rlpList[3].bIntValue()
    }

    func encoded() -> Data {
        return Data()
    }

    func toString() -> String {
        return "ANNOUNCE [blockHash: \(blockHash.toHexString()); blockTotalDifficulty: \(blockTotalDifficulty); blockHeight: \(blockHeight); " +
                "reorganizationDepth: \(reorganizationDepth)]"
    }

}
