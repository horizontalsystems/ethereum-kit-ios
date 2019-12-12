import Foundation
import OpenSslKit

// AES Encryptor that stores the vector state
class AESCipher: IAESCipher {

    private let keySize: Int
    private let key: Data
    private let vector: Data

    init(keySize: Int, key: Data, initialVector: Data? = nil) {
        self.keySize = keySize
        self.key = key

        if let initialVector = initialVector {
            self.vector = initialVector.copy()
        } else {
            self.vector = Data(repeating: 0, count: 16)
        }
    }

    func process(_ data: Data) -> Data {
        return _AES.encrypt(data, withKey: key, keySize: keySize, iv: vector)
    }

}
