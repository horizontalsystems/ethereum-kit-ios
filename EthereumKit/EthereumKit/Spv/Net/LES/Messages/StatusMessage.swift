import BigInt

class StatusMessage: IInMessage, IOutMessage {
    var protocolVersion: Int
    var networkId: Int
    var headTotalDifficulty: BigUInt
    var headHash: Data
    var headHeight: Int
    var genesisHash: Data

    var serveHeaders = false
    var serveChainSince: Int?
    var serveStateSince: Int?

    var flowControlBL: Int = 0
    var flowControlMRR: Int = 0
    var flowControlMRC: [MaxCost] = []

    init(protocolVersion: Int, networkId: Int, genesisHash: Data, headTotalDifficulty: BigUInt, headHash: Data, headHeight: Int) {
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
        headTotalDifficulty = try StatusMessage.valueElement(rlpList: rlpList, name: "headTd").bigIntValue()
        headHash = try StatusMessage.valueElement(rlpList: rlpList, name: "headHash").dataValue
        headHeight = try StatusMessage.valueElement(rlpList: rlpList, name: "headNum").intValue()
        genesisHash = try StatusMessage.valueElement(rlpList: rlpList, name: "genesisHash").dataValue

        serveHeaders = try StatusMessage.optionalValueElement(rlpList: rlpList, name: "serveHeaders") != nil
        serveChainSince = try StatusMessage.optionalValueElement(rlpList: rlpList, name: "serveChainSince")?.intValue()
        serveStateSince = try StatusMessage.optionalValueElement(rlpList: rlpList, name: "serveStateSince")?.intValue()

        flowControlBL = try StatusMessage.valueElement(rlpList: rlpList, name: "flowControl/BL").intValue()
        flowControlMRR = try StatusMessage.valueElement(rlpList: rlpList, name: "flowControl/MRR").intValue()

        let maxCostTable = try StatusMessage.valueElement(rlpList: rlpList, name: "flowControl/MRC").listValue()
        flowControlMRC = try maxCostTable.map { try MaxCost(rlp: $0) }
    }

    func encoded() -> Data {
        let toEncode: [[Any]] = [
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
                "bestHash: \(headHash.toHexString()); bestNum: \(headHeight); genesisHash: \(genesisHash.toHexString()); serveHeaders: \(serveHeaders); " +
                "serveChainSince: \(serveChainSince.map { "\($0)" } ?? "nil"); serveStateSince: \(serveStateSince.map { "\($0)" } ?? "nil"); " +
                "flowControlBL: \(flowControlBL.flowControlLog); flowControlMRR: \(flowControlMRR.flowControlLog); flowControlMRC: [\(flowControlMRC.map { "\n" + $0.toString() }.joined(separator: ", "))]]"
    }

}

extension StatusMessage {

    static func valueElement(rlpList: [RLPElement], name: String) throws -> RLPElement {
        for rlpElement in rlpList {
            let list = try rlpElement.listValue()
            let elementName = try list[0].stringValue()
            if elementName == name {
                return list[1]
            }
        }

        throw MessageDecodeError.fieldNotFound
    }

    static func optionalValueElement(rlpList: [RLPElement], name: String) throws -> RLPElement? {
        for rlpElement in rlpList {
            let list = try rlpElement.listValue()
            let elementName = try list[0].stringValue()
            if elementName == name {
                return list.count > 1 ? list[1] : nil
            }
        }

        return nil
    }

}
