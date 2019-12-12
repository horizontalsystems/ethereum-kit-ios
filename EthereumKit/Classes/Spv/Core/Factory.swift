import Foundation
import OpenSslKit

class Factory: IFactory {

    static let shared = Factory()

    func authMessage(signature: Data, publicKeyPoint: ECPoint, nonce: Data) -> AuthMessage {
        return AuthMessage(signature: signature, publicKeyPoint: publicKeyPoint, nonce: nonce)
    }

    func authAckMessage(data: Data) throws -> AuthAckMessage {
        return try AuthAckMessage(data: data)
    }

    func keccakDigest() -> KeccakDigest {
        return KeccakDigest()
    }

    func frameCodec(secrets: Secrets) -> FrameCodec {
        return FrameCodec(
                secrets: secrets, helper: FrameCodecHelper(crypto: CryptoUtils.shared),
                encryptor: AESCipher(keySize: 256, key: secrets.aes), decryptor: AESCipher(keySize: 256, key: secrets.aes)
        )
    }

    func encryptionHandshake(myKey: ECKey, publicKey: Data) -> EncryptionHandshake {
        return EncryptionHandshake(
                myKey: myKey, publicKeyPoint: ECPoint(nodeId: publicKey),
                crypto: CryptoUtils.shared, randomHelper: RandomHelper.shared, factory: self
        )
    }

}
