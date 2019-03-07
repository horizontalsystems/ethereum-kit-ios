class StatusMessage: IMessage {
    var protocolVersion: UInt8 = 0
    var networkId: Int = 0
    var headTotalDifficulty = Data()
    var headHash = Data()
    var headHeight = BInt(0)
    var genesisHash = Data()

    init(protocolVersion: UInt8, networkId: Int, genesisHash: Data, headTotalDifficulty: Data, headHash: Data, headHeight: BInt) {
        self.protocolVersion = protocolVersion
        self.networkId = networkId
        self.genesisHash = genesisHash
        self.headTotalDifficulty = headTotalDifficulty
        self.headHash = headHash
        self.headHeight = headHeight
    }

    required init(data: Data) throws {
        let rlpList = try RLP.decode(input: data).listValue()

        guard rlpList.count > 5 else {
            throw MessageDecodeError.notEnoughFields
        }

        for rlpElement in rlpList {
            let name = try rlpElement.listValue()[0].stringValue()
            let valueElement = try rlpElement.listValue()[1]

            switch name {
            case "protocolVersion": protocolVersion = UInt8(try valueElement.intValue())
            case "networkId": networkId = try valueElement.intValue()
            case "headTd": headTotalDifficulty = valueElement.dataValue
            case "headHash": headHash = valueElement.dataValue
            case "headNum": headHeight = try valueElement.bIntValue()
            case "genesisHash": genesisHash = valueElement.dataValue
            default: ()
            }
        }
    }

    func encoded() -> Data {
        let toEncode: [Any] = [
            ["protocolVersion", Int(protocolVersion)],
            ["networkId", networkId],
            ["headTd", headTotalDifficulty],
            ["headHash", headHash],
            ["headNum", headHeight],
            ["genesisHash", genesisHash],
            ["announceType", 1]
        ]

        return RLP.encode(toEncode)
    }

    func toString() -> String {
        return "STATUS [protocolVersion: \(protocolVersion); networkId: \(networkId); totalDifficulty: \(headTotalDifficulty.toHexString()); " + 
                "bestHash: \(headHash.toHexString()); bestNum: \(headHeight); genesisHash: \(genesisHash.toHexString())]"
    }
}
