class StatusMessage: IInMessage, IOutMessage {
    var protocolVersion: Int
    var networkId: Int
    var headTotalDifficulty: BInt
    var headHash: Data
    var headHeight: BInt
    var genesisHash: Data

    init(protocolVersion: Int, networkId: Int, genesisHash: Data, headTotalDifficulty: BInt, headHash: Data, headHeight: BInt) {
        self.protocolVersion = protocolVersion
        self.networkId = networkId
        self.genesisHash = genesisHash
        self.headTotalDifficulty = headTotalDifficulty
        self.headHash = headHash
        self.headHeight = headHeight
    }

    required init(data: Data) throws {
        let rlpList = try RLP.decode(input: data).listValue()

        protocolVersion = try StatusMessage.valueElement(rlpList: rlpList, name: "protocolVersion").intValue()
        networkId = try StatusMessage.valueElement(rlpList: rlpList, name: "networkId").intValue()
        headTotalDifficulty = try StatusMessage.valueElement(rlpList: rlpList, name: "headTd").bIntValue()
        headHash = try StatusMessage.valueElement(rlpList: rlpList, name: "headHash").dataValue
        headHeight = try StatusMessage.valueElement(rlpList: rlpList, name: "headNum").bIntValue()
        genesisHash = try StatusMessage.valueElement(rlpList: rlpList, name: "genesisHash").dataValue
    }

    func encoded() -> Data {
        let toEncode: [Any] = [
            ["protocolVersion", protocolVersion],
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
        return "STATUS [protocolVersion: \(protocolVersion); networkId: \(networkId); totalDifficulty: \(headTotalDifficulty); " + 
                "bestHash: \(headHash.toHexString()); bestNum: \(headHeight); genesisHash: \(genesisHash.toHexString())]"
    }

}

extension StatusMessage {

    static func valueElement(rlpList: [RLPElement], name: String) throws -> RLPElement {
        for rlpElement in rlpList {
            let list = try rlpElement.listValue()
            if name == (try list[0].stringValue()) {
                return list[1]
            }
        }

        throw MessageDecodeError.fieldNotFound
    }

}
