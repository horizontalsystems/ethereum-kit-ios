import Foundation
import HSCryptoKit


class ECIES {

    enum ECIESError : Error {
        case macMismatch
    }

    // 128 bit EC public key, IV, 256 bit MAC
    static let prefix = 65 + 128 / 8 + 32

    public static func encrypt(remotePublicKey: ECPoint, message: Data) -> Data {
        var prefix = UInt16(ECIES.prefix + message.count)
        let prefixBytes = Data(Data(bytes: &prefix, count: MemoryLayout<UInt16>.size).reversed())

        let initialVector = Crypto().randomBytes(length: 16)
        let ephemeralKey = ECKey.randomKey()

        let sharedSecret = CryptoKit.ecdhAgree(privateKey: ephemeralKey.privateKey, withPublicKey: remotePublicKey.uncompressed())
        let derivedKey: Data = _Hash.concatKDF(sharedSecret)
        let aesKey = derivedKey.subdata(in: 0..<16)
        let macKey = _Hash.sha256(derivedKey.subdata(in: 16..<32))

        let cipher: Data = _AES.encrypt(message, withKey: aesKey, keySize: 128, iv: initialVector.copy())
        let hmac: Data = _Hash.hmacsha256(cipher, key: macKey, iv: initialVector, macData: prefixBytes)

        var encrypted = Data()
        encrypted.append(ephemeralKey.publicKeyPoint.uncompressed())
        encrypted.append(initialVector)
        encrypted.append(cipher)
        encrypted.append(hmac)

        return prefixBytes + encrypted
    }

    class func decrypt(privateKey: Data, message: Data) throws -> Data {
        let prefixBytes: Data = message.subdata(in: 0..<2)
        let prefix = Data(prefixBytes.reversed()).to(type: UInt16.self)
        let message = message.subdata(in: 2..<Int(prefix + 2))

        let length = message.count
        let remoteEphemeralPubKeyPoint = ECPoint(nodeId: message.subdata(in: 1..<65))

        let initialVector = message.subdata(in: 65..<(65 + 16))
        let cipher = message.subdata(in: (65+16)..<(length-32))
        let hmacGiven = message.suffix(from: (length-32))

        let sharedSecret = CryptoKit.ecdhAgree(privateKey: privateKey, withPublicKey: remoteEphemeralPubKeyPoint.uncompressed())
        let derivedKey: Data = _Hash.concatKDF(sharedSecret)
        let aesKey = derivedKey.subdata(in: 0..<16)
        let macKey = _Hash.sha256(derivedKey.subdata(in: 16..<32))

        let decryptedMessage: Data = _AES.encrypt(cipher, withKey: aesKey, keySize: 128, iv: initialVector.copy())
        let hmacCalculated: Data = _Hash.hmacsha256(cipher, key: macKey, iv: initialVector, macData: prefixBytes)

        guard hmacGiven == hmacCalculated else {
            throw ECIESError.macMismatch
        }

        return decryptedMessage
    }

}
