import Foundation
import HSCryptoKit

class Crypto: ICrypto {

    func randomKey() -> ECKey {
        return ECKey.randomKey()
    }

    func randomBytes(length: Int) -> Data {
        var bytes = Data(count: length)
        let _ = bytes.withUnsafeMutableBytes {
            (mutableBytes: UnsafeMutablePointer<UInt8>) -> Int32 in
            SecRandomCopyBytes(kSecRandomDefault, length, mutableBytes)
        }

        return bytes
    }

    func ecdhAgree(myKey: ECKey, remotePublicKeyPoint: ECPoint) -> Data {
        return CryptoKit.ecdhAgree(privateKey: myKey.privateKey, withPublicKey: remotePublicKeyPoint.uncompressed())
    }

    func ellipticSign(_ messageToSign: Data, key: ECKey) throws -> Data {
        return try CryptoKit.ellipticSign(messageToSign, privateKey: key.privateKey)
    }

    func eciesDecrypt(privateKey: Data, message: Data) throws -> Data {
        return try ECIES.decrypt(privateKey: privateKey, message: message)
    }

    func eciesEncrypt(remotePublicKey: ECPoint, message: Data) -> Data {
        return ECIES.encrypt(remotePublicKey: remotePublicKey, message: message)
    }

    func sha3(_ data: Data) -> Data {
        return CryptoKit.sha3(data)
    }

}
