import Foundation
import HSCryptoKit

class ECKey {

    var privateKey: Data
    var publicKeyPoint: ECPoint

    init(privateKey: Data, publicKeyPoint: ECPoint) {
        self.privateKey = privateKey
        self.publicKeyPoint = publicKeyPoint
    }

    public static func randomKey() -> ECKey {
        let key: _ECKey = _ECKey.random()
        return ECKey(privateKey: key.privateKey, publicKeyPoint: ECPoint(nodeId: key.publicKey.subdata(in: 1..<65)))
    }

    public func toString() -> String {
        return "[privateKey: \(privateKey.toHexString()); publicKey: \(publicKeyPoint.toString())]"
    }

}