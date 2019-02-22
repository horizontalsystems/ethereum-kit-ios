import Foundation
import HSCryptoKit

class Crypto: ICrypto {

    let eciesEngine = ECIESEngine()

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

    func eciesDecrypt(privateKey: Data, message: ECIESEncryptedMessage) throws -> Data {
        return try eciesEngine.decrypt(crypto: self, privateKey: privateKey, message: message)
    }

    func eciesEncrypt(remotePublicKey: ECPoint, message: Data) -> ECIESEncryptedMessage {
        return eciesEngine.encrypt(crypto: self, remotePublicKey: remotePublicKey, message: message)
    }

    func sha3(_ data: Data) -> Data {
        return CryptoKit.sha3(data)
    }

}

extension Crypto: IECIESCrypto {

    func concatKDF(_ data: Data) -> Data {
        return _Hash.concatKDF(data)
    }

    func sha256(_ data: Data) -> Data {
        return _Hash.sha256(data)
    }

    func aesEncrypt(_ data: Data, withKey: Data, keySize: Int, iv: Data) -> Data {
        return _AES.encrypt(data, withKey: withKey, keySize: keySize, iv: iv.copy())
    }

    func hmacSha256(_ data: Data, key: Data, iv: Data, macData: Data) -> Data {
        return _Hash.hmacsha256(data, key: key, iv: iv, macData: macData)
    }

    func ecdhAgree(myPrivateKey: Data, remotePublicKeyPoint: Data) -> Data {
        return CryptoKit.ecdhAgree(privateKey: myPrivateKey, withPublicKey: remotePublicKeyPoint)
    }
}
