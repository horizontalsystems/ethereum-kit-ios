import Foundation

class AuthMessage {
    
    static let version: Int = 4
    
    let signature: Data
    let publicKeyPoint: ECPoint
    let nonce: Data
    
    init(signature: Data, publicKeyPoint: ECPoint, nonce: Data) {
        self.signature = signature
        self.publicKeyPoint = publicKeyPoint
        self.nonce = nonce
    }
    
    func encoded() -> Data {
        let toEncode: [Any] = [
            self.signature,
            self.publicKeyPoint.x + self.publicKeyPoint.y,
            self.nonce,
            AuthMessage.version
        ]
        
        return RLP.encode(toEncode)
    }
    
}
