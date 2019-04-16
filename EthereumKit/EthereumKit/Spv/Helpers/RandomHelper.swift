import Foundation
import HSCryptoKit

class RandomHelper: IRandomHelper {
    static let shared = RandomHelper()

    var randomInt: Int {
        return Int.random(in: 0..<Int.max)
    }

    func randomKey() -> ECKey {
        let key: _ECKey = _ECKey.random()
        return ECKey(privateKey: key.privateKey, publicKeyPoint: ECPoint(nodeId: key.publicKey.subdata(in: 1..<65)))
    }

    func randomBytes(length: Range<Int>) -> Data {
        return randomBytes(length: Int.random(in: length))
    }

    func randomBytes(length: Int) -> Data {
        var bytes = Data(count: length)
        let _ = bytes.withUnsafeMutableBytes {
            (mutableBytes: UnsafeMutablePointer<UInt8>) -> Int32 in
            SecRandomCopyBytes(kSecRandomDefault, length, mutableBytes)
        }

        return bytes
    }

}
