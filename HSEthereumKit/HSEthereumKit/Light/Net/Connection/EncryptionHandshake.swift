import Foundation
import HSCryptoKit
import Security

class EncryptionHandshake {

    enum HandshakeError: Error {
        case invalidAuthAckPayload
    }

    static let NONCE_SIZE: Int = 32

    let myKey: ECKey
    let ephemeralKey: ECKey
    let remotePublicKeyPoint: ECPoint
    let initiatorNonce: Data
    var authMessagePacket = Data()
    var authAckMessagePacket = Data()


    init(myKey: ECKey, publicKeyPoint: ECPoint) {
        self.myKey = myKey
        remotePublicKeyPoint = publicKeyPoint
        ephemeralKey = ECKey.randomKey()
        initiatorNonce = randomBytes(length: 32)
    }

    func createAuthMessage() throws {
        let sharedSecret = CryptoKit.ecdhAgree(privateKey: myKey.privateKey, withPublicKey: remotePublicKeyPoint.uncompressed())

        let messageToSign = sharedSecret.xor(with: initiatorNonce)
        let signature = try CryptoKit.ellipticSign(messageToSign, privateKey: ephemeralKey.privateKey)

        let message = AuthMessage(signature: signature, publicKeyPoint: myKey.publicKeyPoint, nonce: initiatorNonce)
        authMessagePacket = encrypt(authMessage: message)
    }

    func extractSecretsFromResponse(in responsePackets: Data) throws -> Secrets {
        let prefixBytes: Data = responsePackets.subdata(in: 0..<2)
        let prefix = Data(prefixBytes.reversed()).to(type: UInt16.self)
        let responseData = responsePackets.subdata(in: 2..<Int(prefix + 2))

        authAckMessagePacket = prefixBytes + responseData
        let responseDecrypted = try ECIES.decrypt(privateKey: myKey.privateKey, message: responseData, macData: prefixBytes)

        guard let message = AuthAckMessage(data: responseDecrypted) else {
            throw HandshakeError.invalidAuthAckPayload
        }

        return extractSecrets(message: message)
    }


    private func encrypt(authMessage message: AuthMessage) -> Data {
        let encodedMessage = message.encoded()
        let padded = eip8pad(message: encodedMessage)

        var prefix = UInt16(ECIES.prefix + padded.count)
        let prefixBytes = Data(Data(bytes: &prefix, count: MemoryLayout<UInt16>.size).reversed())

        let eciesEncrypted = ECIES.encrypt(remotePublicKey: remotePublicKeyPoint, message: padded, macData: prefixBytes)
        let encrypted: Data = prefixBytes + eciesEncrypted

        return encrypted
    }

    private func extractSecrets(message: AuthAckMessage) -> Secrets {
        let sPointer: UnsafeMutablePointer<UInt8> = _ECDH.agree(ephemeralKey.privateKey, withPublicKey: message.publicKeyPoint.uncompressed())
        let ephemeralSharedSecret = Data(buffer: UnsafeBufferPointer(start: sPointer, count: 32))

        let sharedSecret = CryptoKit.sha3(ephemeralSharedSecret + CryptoKit.sha3(message.nonce + initiatorNonce))

        let aes = CryptoKit.sha3(ephemeralSharedSecret + sharedSecret)
        let mac = CryptoKit.sha3(ephemeralSharedSecret + aes)
        let token = CryptoKit.sha3(sharedSecret)

        let egressMac = KeccakDigest()
        egressMac.update(with: mac.xor(with: message.nonce))
        egressMac.update(with: authMessagePacket)

        let ingressMac = KeccakDigest()
        ingressMac.update(with: mac.xor(with: initiatorNonce))
        ingressMac.update(with: authAckMessagePacket)

        return Secrets(aes: aes, mac: mac, token: token, egressMac: egressMac, ingressMac: ingressMac)
    }

    private func eip8pad(message: Data) -> Data {
        let junkLength = Int.random(in: 100..<300)

        return message + randomBytes(length: junkLength)
    }

}
