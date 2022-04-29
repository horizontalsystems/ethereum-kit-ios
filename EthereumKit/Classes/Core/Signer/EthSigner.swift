import BigInt
import Secp256k1Kit

class EthSigner {
    private let privateKey: Data
    private let cryptoUtils: ICryptoUtils

    init(privateKey: Data, cryptoUtils: ICryptoUtils) {
        self.privateKey = privateKey
        self.cryptoUtils = cryptoUtils
    }

    private func prefixed(message: Data) -> Data? {
        guard let string = String(data: message, encoding: .utf8) else {
            return nil
        }

        let prefix = "\u{0019}Ethereum Signed Message:\n\(message.count)"

        guard let prefixData = prefix.data(using: .utf8) else {
            return nil
        }

        return cryptoUtils.sha3(prefixData + message)
    }

    public func sign(message: Data) throws -> Data {
        try cryptoUtils.ellipticSign(prefixed(message: message) ?? message, privateKey: privateKey)
    }

    public func parseTypedData(rawJson: Data) throws -> EIP712TypedData {
        let decoder = JSONDecoder()
        return try decoder.decode(EIP712TypedData.self, from: rawJson)
    }

    func signTypedData(message: Data) throws -> Data {
        let typedData = try parseTypedData(rawJson: message)
        let hashedMessage = typedData.signHash

        return try cryptoUtils.ellipticSign(hashedMessage, privateKey: privateKey)
    }

}
