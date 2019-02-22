import Foundation

class ECIESEncryptedMessage {

    let prefixBytes: Data
    let ephemeralPublicKey: Data
    let initialVector: Data
    let cipher: Data
    let checksum: Data

    init(prefixBytes: Data, ephemeralPublicKey: Data, initialVector: Data, cipher: Data, checksum: Data) {
        self.prefixBytes = prefixBytes
        self.ephemeralPublicKey = ephemeralPublicKey
        self.initialVector = initialVector
        self.cipher = cipher
        self.checksum = checksum
    }

    init?(data: Data) {
        guard data.count > ECIESEngine.prefix else {
            return nil
        }

        prefixBytes = data.subdata(in: 0..<2)
        let prefix = Data(prefixBytes.reversed()).to(type: UInt16.self)
        let length = Int(prefix)

        guard data.count > length + 2 else {
            return nil
        }

        let message = data.subdata(in: 2..<(length + 2))

        ephemeralPublicKey = message.subdata(in: 0..<65)
        initialVector = message.subdata(in: 65..<(65 + 16))
        cipher = message.subdata(in: (65 + 16)..<(length - 32))
        checksum = message.suffix(from: (length - 32))
    }

    func encoded() -> Data {
        var data = Data()
        data.append(prefixBytes)
        data.append(ephemeralPublicKey)
        data.append(initialVector)
        data.append(cipher)
        data.append(checksum)

        return data
    }
}
