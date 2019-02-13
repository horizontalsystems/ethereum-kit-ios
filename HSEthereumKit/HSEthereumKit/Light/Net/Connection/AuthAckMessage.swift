import Foundation

class AuthAckMessage {
    
    let publicKeyPoint: ECPoint
    let nonce: Data
    let version: Data
    
    init(data: Data) {
        let rlpMap = try! RLP.decode(input: data)
        
        publicKeyPoint = ECPoint(nodeId: rlpMap.listValue[0].dataValue)
        nonce = rlpMap.listValue[1].dataValue
        version = rlpMap.listValue[2].dataValue
    }
    
    func toString() -> String {
        return "\n  \(publicKeyPoint.toString())\n  \(nonce.toHexString())\n  \(version.toHexString())"
    }

}
