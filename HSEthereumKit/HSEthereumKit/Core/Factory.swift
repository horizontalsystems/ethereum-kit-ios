import Foundation
import HSCryptoKit

class Factory: IFactory {

    func authMessage(signature: Data, publicKeyPoint: ECPoint, nonce: Data) -> AuthMessage {
        return AuthMessage(signature: signature, publicKeyPoint: publicKeyPoint, nonce: nonce)
    }

    func authAckMessage(data: Data) -> AuthAckMessage? {
        return AuthAckMessage(data: data)
    }

    func keccakDigest() -> KeccakDigest {
        return KeccakDigest()
    }

}
