import Foundation

class StatusMessage: IMessage {

    var protocolVersion: UInt8 = 0
    var networkId: Int = 0
    var bestBlockTotalDifficulty = Data()
    var bestBlockHash = Data()
    var bestBlockHeight = BInt(0)
    var genesisHash = Data()

    init(protocolVersion: UInt8, networkId: Int, genesisHash: Data, bestBlockTotalDifficulty: Data, bestBlockHash: Data, bestBlockHeight: BInt) {
        self.protocolVersion = protocolVersion
        self.networkId = networkId
        self.genesisHash = genesisHash
        self.bestBlockTotalDifficulty = bestBlockTotalDifficulty
        self.bestBlockHash = bestBlockHash
        self.bestBlockHeight = bestBlockHeight
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
            case "headTd": bestBlockTotalDifficulty = valueElement.dataValue
            case "headHash": bestBlockHash = valueElement.dataValue
            case "headNum": bestBlockHeight = try valueElement.bIntValue()
            case "genesisHash": genesisHash = valueElement.dataValue
            default: ()
            }
        }
    }

    func encoded() -> Data {
        let toEncode: [Any] = [
            ["protocolVersion", Int(protocolVersion)],
            ["networkId", networkId],
            ["headTd", bestBlockTotalDifficulty],
            ["headHash", bestBlockHash],
            ["headNum", bestBlockHeight],
            ["genesisHash", genesisHash],
            ["announceType", 1]
        ]

        return RLP.encode(toEncode)
    }

    func toString() -> String {
        return "STATUS [protocolVersion: \(protocolVersion); networkId: \(networkId); totalDifficulty: \(bestBlockTotalDifficulty.toHexString()); " + 
                "bestHash: \(bestBlockHash.toHexString()); bestNum: \(bestBlockHeight); genesisHash: \(genesisHash.toHexString())]"
    }
}
