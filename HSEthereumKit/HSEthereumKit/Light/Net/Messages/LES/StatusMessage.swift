import Foundation

class StatusMessage: IMessage {

    static let code = 0x10
    var code: Int { return StatusMessage.code }

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

    init(data: Data) {
        let rlpList = try! RLP.decode(input: data)

        for rlpElement in rlpList.listValue {
            let name = rlpElement.listValue[0].stringValue
            let valueElement = rlpElement.listValue[1]

            switch name {
            case "protocolVersion": protocolVersion = UInt8(valueElement.intValue)
            case "networkId": networkId = valueElement.intValue
            case "headTd": bestBlockTotalDifficulty = valueElement.dataValue
            case "headHash": bestBlockHash = valueElement.dataValue
            case "headNum": bestBlockHeight = BInt(valueElement.dataValue.toHexString(), radix: 16)!
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
            ["genesisHash", genesisHash]
        ]

        return try! RLP.encode(toEncode)
    }

    func toString() -> String {
        return "STATUS [protocolVersion: \(protocolVersion); networkId: \(networkId); totalDifficulty: \(bestBlockTotalDifficulty.toHexString()); " + 
                "bestHash: \(bestBlockHash.toHexString()); bestNum: \(bestBlockHeight); genesisHash: \(genesisHash.toHexString())]"
    }
}
