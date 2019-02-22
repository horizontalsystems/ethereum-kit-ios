import Foundation
import HSCryptoKit


class ECIESEngine {

    enum ECIESError : Error {
        case macMismatch
    }

    // 128 bit EC public key, IV, 256 bit MAC
    static let prefix = 65 + 128 / 8 + 32

    func encrypt(crypto: IECIESCrypto, remotePublicKey: ECPoint, message: Data) -> ECIESEncryptedMessage {
        var prefix = UInt16(ECIESEngine.prefix + message.count)
        let prefixBytes = Data(Data(bytes: &prefix, count: MemoryLayout<UInt16>.size).reversed())

        let initialVector = crypto.randomBytes(length: 16)
        let ephemeralKey = crypto.randomKey()

        let sharedSecret = crypto.ecdhAgree(myKey: ephemeralKey, remotePublicKeyPoint: remotePublicKey)
        let derivedKey = crypto.concatKDF(sharedSecret)
        let aesKey = derivedKey.subdata(in: 0..<16)
        let macKey = crypto.sha256(derivedKey.subdata(in: 16..<32))

        let cipher: Data = crypto.aesEncrypt(message, withKey: aesKey, keySize: 128, iv: initialVector)
        let checksum: Data = crypto.hmacSha256(cipher, key: macKey, iv: initialVector, macData: prefixBytes)

        return ECIESEncryptedMessage(prefixBytes: prefixBytes, ephemeralPublicKey: ephemeralKey.publicKeyPoint.uncompressed(), initialVector: initialVector, cipher: cipher, checksum: checksum)
    }

    func decrypt(crypto: IECIESCrypto, privateKey: Data, message: ECIESEncryptedMessage) throws -> Data {
        let sharedSecret = crypto.ecdhAgree(myPrivateKey: privateKey, remotePublicKeyPoint: message.ephemeralPublicKey)
        let derivedKey = crypto.concatKDF(sharedSecret)
        let aesKey = derivedKey.subdata(in: 0..<16)
        let macKey = crypto.sha256(derivedKey.subdata(in: 16..<32))

        let decryptedMessage: Data = crypto.aesEncrypt(message.cipher, withKey: aesKey, keySize: 128, iv: message.initialVector)
        let checksumCalculated: Data = crypto.hmacSha256(message.cipher, key: macKey, iv: message.initialVector, macData: message.prefixBytes)

        guard message.checksum == checksumCalculated else {
            throw ECIESError.macMismatch
        }

        return decryptedMessage
    }

}
