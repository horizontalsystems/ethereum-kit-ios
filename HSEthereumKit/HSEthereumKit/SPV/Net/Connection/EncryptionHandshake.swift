import Foundation
import Security

class EncryptionHandshake {

    static let NONCE_SIZE: Int = 32

    private let crypto: ICryptoUtils
    private let random: IRandomHelper
    private let factory: IFactory
    private let myKey: ECKey
    private let ephemeralKey: ECKey
    private let remotePublicKeyPoint: ECPoint
    private let initiatorNonce: Data
    private var authMessagePacket = Data()

    init(myKey: ECKey, publicKeyPoint: ECPoint, crypto: ICryptoUtils, randomHelper: IRandomHelper, factory: IFactory) {
        self.crypto = crypto
        self.random = randomHelper
        self.factory = factory
        self.myKey = myKey
        remotePublicKeyPoint = publicKeyPoint
        ephemeralKey = random.randomKey()
        initiatorNonce = random.randomBytes(length: 32)
    }

    func createAuthMessage() throws -> Data {
        let sharedSecret = crypto.ecdhAgree(myKey: myKey, remotePublicKeyPoint: remotePublicKeyPoint)
        let messageToSign = sharedSecret.xor(with: initiatorNonce)
        let signature = try crypto.ellipticSign(messageToSign, key: ephemeralKey)
        let message = factory.authMessage(signature: signature, publicKeyPoint: myKey.publicKeyPoint, nonce: initiatorNonce)

        authMessagePacket = encrypt(authMessage: message)
        return authMessagePacket
    }

    func extractSecrets(from eciesMessage: ECIESEncryptedMessage) throws -> Secrets {
        let responseDecrypted = try crypto.eciesDecrypt(privateKey: myKey.privateKey, message: eciesMessage)
        let message = try factory.authAckMessage(data: responseDecrypted)

        return extractSecrets(message: message, authAckMessagePacket: eciesMessage.encoded())
    }


    private func encrypt(authMessage message: AuthMessage) -> Data {
        let encodedMessage = message.encoded() + eip8padding()
        let eciesMessage = crypto.eciesEncrypt(remotePublicKey: remotePublicKeyPoint, message: encodedMessage)

        return eciesMessage.encoded()
    }

    private func extractSecrets(message: AuthAckMessage, authAckMessagePacket: Data) -> Secrets {
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
        return random.randomBytes(length: 100..<300)
    }

}
