import Foundation

class AuthAckMessage {
    
    let publicKeyPoint: ECPoint
    let nonce: Data
    let version: Data
    
    required init(data: Data) throws {
        let rlpList = try RLP.decode(input: data).listValue()

        guard rlpList.count > 2 else {
            throw MessageDecodeError.notEnoughFields
        }

        publicKeyPoint = ECPoint(nodeId: rlpList[0].dataValue)
        nonce = rlpList[1].dataValue
        version = rlpList[2].dataValue
    }
    
    func toString() -> String {
        return "\n  \(publicKeyPoint.toString())\n  \(nonce.toHexString())\n  \(version.toHexString())"
    }

}
