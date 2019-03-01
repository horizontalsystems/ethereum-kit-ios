import Foundation

class AuthAckMessage {
    
    let publicKeyPoint: ECPoint
    let nonce: Data
    let version: Data
    
    init?(data: Data) {
        let rlp = RLP.decode(input: data)

        guard rlp.isList() && rlp.listValue.count > 2 else {
            return nil
        }
        
        publicKeyPoint = ECPoint(nodeId: rlp.listValue[0].dataValue)
        nonce = rlp.listValue[1].dataValue
        version = rlp.listValue[2].dataValue
    }
    
    func toString() -> String {
        return "\n  \(publicKeyPoint.toString())\n  \(nonce.toHexString())\n  \(version.toHexString())"
    }

}
