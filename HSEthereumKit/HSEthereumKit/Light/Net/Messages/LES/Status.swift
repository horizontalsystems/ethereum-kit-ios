import Foundation

class StatusMessage : IMessage {

    static let code = 0x10
    var code: Int { return StatusMessage.code }

    var protocolVersion: UInt8 = 0
    var networkId: Int = 0
    var totalDifficulty = Data()
    var bestHash = Data()
    var bestNum = BInt(0)
    var genesisHash = Data()

    init(data: Data) {
        let rlpList = try! RLP.decode(input: data)

        for rlpElement in rlpList.listValue {
            let name = rlpElement.listValue[0].stringValue
            let valueElement = rlpElement.listValue[1]

            switch name {
            case "protocolVersion": protocolVersion = UInt8(valueElement.intValue)
            case "networkId": networkId = valueElement.intValue
            case "headTd": totalDifficulty = valueElement.dataValue
            case "headHash": bestHash = valueElement.dataValue
            case "headNum": bestNum = BInt(valueElement.dataValue.toHexString(), radix: 16)!
            case "genesisHash": genesisHash = valueElement.dataValue
            default: ()
            }
        }
    }

    func encoded() -> Data {
        return Data()
    }

    func toString() -> String {
        return "[protocolVersion: \(protocolVersion); networkId: \(networkId); totalDifficulty: \(totalDifficulty.toHexString()); " + 
                "bestHash: \(bestHash.toHexString()); bestNum: \(bestNum); genesisHash: \(genesisHash.toHexString())]"
    }
}
