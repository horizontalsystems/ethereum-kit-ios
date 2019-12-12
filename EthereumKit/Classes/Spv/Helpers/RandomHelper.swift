import Foundation
import OpenSslKit

class RandomHelper: IRandomHelper {
    static let shared = RandomHelper()

    let ecKeyQueue = DispatchQueue(label: "ecKeyQueue", qos: .userInitiated)

    var randomInt: Int {
        return Int.random(in: 0..<Int.max)
    }

    func randomKey() -> ECKey {
        var key: _ECKey!

        ecKeyQueue.sync {
            key = _ECKey.random()
        }

        return ECKey(privateKey: key.privateKey, publicKeyPoint: ECPoint(nodeId: key.publicKey.subdata(in: 1..<65)))
    }

    func randomBytes(length: Range<Int>) -> Data {
        return randomBytes(length: Int.random(in: length))
    }

    func randomBytes(length: Int) -> Data {
        var bytes = Data(count: length)
        let _ = bytes.withUnsafeMutableBytes { mutableBytes -> Int32 in
            SecRandomCopyBytes(kSecRandomDefault, length, mutableBytes.baseAddress!.assumingMemoryBound(to: UInt8.self))
        }

        return bytes
    }

}
