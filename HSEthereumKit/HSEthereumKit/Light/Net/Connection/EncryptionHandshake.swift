import Foundation
import HSCryptoKit
import Security

class EncryptionHandshake {

    enum HandshakeError: Error {
        case invalidAuthAckPayload
    }

    static let NONCE_SIZE: Int = 32

    let crypto: ICrypto
    let factory: IFactory
    let myKey: ECKey
    let ephemeralKey: ECKey
    let remotePublicKeyPoint: ECPoint
    let initiatorNonce: Data
    var authMessagePacket = Data()
    var authAckMessagePacket = Data()


    init(myKey: ECKey, publicKeyPoint: ECPoint, crypto: ICrypto, factory: IFactory) {
        self.crypto = crypto
        self.factory = factory
        self.myKey = myKey
        remotePublicKeyPoint = publicKeyPoint
        ephemeralKey = crypto.randomKey()
        initiatorNonce = crypto.randomBytes(length: 32)
    }

    func createAuthMessage() throws {
        let sharedSecret = crypto.ecdhAgree(myKey: myKey, remotePublicKeyPoint: remotePublicKeyPoint)

        let messageToSign = sharedSecret.xor(with: initiatorNonce)
        let signature = try crypto.ellipticSign(messageToSign, key: ephemeralKey)

        let message = factory.authMessage(signature: signature, publicKeyPoint: myKey.publicKeyPoint, nonce: initiatorNonce)
        authMessagePacket = encrypt(authMessage: message)
    }

    func extractSecretsFromResponse(in responsePackets: Data) throws -> Secrets {
        authAckMessagePacket = responsePackets
        let responseDecrypted = try crypto.eciesDecrypt(privateKey: myKey.privateKey, message: responsePackets)

        guard let message = factory.authAckMessage(data: responseDecrypted) else {
            throw HandshakeError.invalidAuthAckPayload
        }

        return extractSecrets(message: message)
    }


    private func encrypt(authMessage message: AuthMessage) -> Data {
        let encodedMessage = message.encoded() + eip8padding()
        let eciesEncrypted = crypto.eciesEncrypt(remotePublicKey: remotePublicKeyPoint, message: encodedMessage)

        return eciesEncrypted
    }

    private func extractSecrets(message: AuthAckMessage) -> Secrets {
        let ephemeralSharedSecret = crypto.ecdhAgree(myKey: ephemeralKey, remotePublicKeyPoint: message.publicKeyPoint)

        let sharedSecret = crypto.sha3(ephemeralSharedSecret + crypto.sha3(message.nonce + initiatorNonce))
        let aes = crypto.sha3(ephemeralSharedSecret + sharedSecret)
        let mac = crypto.sha3(ephemeralSharedSecret + aes)
        let token = crypto.sha3(sharedSecret)

        let egressMac = factory.keccakDigest()
        egressMac.update(with: mac.xor(with: message.nonce))
        egressMac.update(with: authMessagePacket)

        let ingressMac = factory.keccakDigest()
        ingressMac.update(with: mac.xor(with: initiatorNonce))
        ingressMac.update(with: authAckMessagePacket)

        return Secrets(aes: aes, mac: mac, token: token, egressMac: egressMac, ingressMac: ingressMac)
    }

    private func eip8padding() -> Data {
        let junkLength = Int.random(in: 100..<300)

        return crypto.randomBytes(length: junkLength)
    }

}
