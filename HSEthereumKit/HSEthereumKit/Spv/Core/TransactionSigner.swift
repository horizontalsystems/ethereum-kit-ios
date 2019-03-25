import HSCryptoKit

class TransactionSigner {
    private let chainId: Int
    private let rawPrivateKey: Data

    init(network: INetwork, rawPrivateKey: Data) {
        chainId = network.id
        self.rawPrivateKey = rawPrivateKey
    }

    func sign(rawTransaction: RawTransaction) throws -> (v: BInt, r: BInt, s: BInt) {
        var toEncode: [Any] = [
            rawTransaction.nonce,
            rawTransaction.gasPrice,
            rawTransaction.gasLimit,
            rawTransaction.to.data,
            rawTransaction.value,
            rawTransaction.data
        ]

        if chainId != 0 {
            toEncode.append(contentsOf: [chainId, 0, 0 ]) // EIP155
        }

        let encodedData = RLP.encode(toEncode)
        let rawTransactionHash = CryptoKit.sha3(encodedData)

        let signature = try CryptoKit.ellipticSign(rawTransactionHash, privateKey: rawPrivateKey)

        return calculateVRS(signature: signature)
    }

    func hash(rawTransaction: RawTransaction, signature: (v: BInt, r: BInt, s: BInt)) -> Data {
        let encodedData = RLP.encode([
            rawTransaction.nonce,
            rawTransaction.gasPrice,
            rawTransaction.gasLimit,
            rawTransaction.to.data,
            rawTransaction.value,
            rawTransaction.data,
            signature.v,
            signature.r,
            signature.s
        ])

        return CryptoKit.sha3(encodedData)
    }

    private func calculateVRS(signature: Data) -> (v: BInt, r: BInt, s: BInt) {
        return (
                v: BInt(signature[64]) + (chainId == 0 ? 27 : (35 + 2 * chainId)),
                r: BInt(str: signature[..<32].toHexString(), radix: 16)!,
                s: BInt(str: signature[32..<64].toHexString(), radix: 16)!
        )
    }

}
