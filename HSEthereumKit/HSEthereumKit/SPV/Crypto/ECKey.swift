import Foundation

class ECKey {

    var privateKey: Data
    var publicKeyPoint: ECPoint

    init(privateKey: Data, publicKeyPoint: ECPoint) {
        self.privateKey = privateKey
        self.publicKeyPoint = publicKeyPoint
    }

    public func toString() -> String {
        return "[privateKey: \(privateKey.toHexString()); publicKey: \(publicKeyPoint.toString())]"
    }

}