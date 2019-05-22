import HSCryptoKit
import BigInt

class TransactionSigner {
    private let chainId: Int
    private let privateKey: Data

    init(network: INetwork, privateKey: Data) {
        chainId = network.chainId
        self.privateKey = privateKey
    }

    func sign(rawTransaction: RawTransaction, nonce: Int) throws -> Data {
        var toEncode: [Any] = [
            nonce,
            rawTransaction.gasPrice,
            rawTransaction.gasLimit,
            rawTransaction.to,
            rawTransaction.value,
            rawTransaction.data
        ]

        if chainId != 0 {
            toEncode.append(contentsOf: [chainId, 0, 0 ]) // EIP155
        }

        let encodedData = RLP.encode(toEncode)
        let rawTransactionHash = CryptoKit.sha3(encodedData)

        return try CryptoKit.ellipticSign(rawTransactionHash, privateKey: privateKey)
    }

    func signature(rawTransaction: RawTransaction, nonce: Int) throws -> Signature {
        let signatureData: Data = try sign(rawTransaction: rawTransaction, nonce: nonce)

        return signature(from: signatureData)
    }

    func signature(from data: Data) -> Signature {
        return Signature(
                v: Int(data[64]) + (chainId == 0 ? 27 : (35 + 2 * chainId)),
                r: BigUInt(data[..<32].toRawHexString(), radix: 16)!,
                s: BigUInt(data[32..<64].toRawHexString(), radix: 16)!
        )
    }

}
