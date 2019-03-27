import HSCryptoKit

class TransactionSigner {
    private let chainId: Int
    private let privateKey: Data

    init(network: INetwork, privateKey: Data) {
        chainId = network.chainId
        self.privateKey = privateKey
    }

    func sign(rawTransaction: RawTransaction, nonce: Int) throws -> Signature {
        var toEncode: [Any] = [
            nonce,
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

        let signature = try CryptoKit.ellipticSign(rawTransactionHash, privateKey: privateKey)

        return calculateVRS(signature: signature)
    }

    private func calculateVRS(signature: Data) -> Signature {
        return Signature(
                v: Int(signature[64]) + (chainId == 0 ? 27 : (35 + 2 * chainId)),
                r: BInt(str: signature[..<32].toHexString(), radix: 16)!,
                s: BInt(str: signature[32..<64].toHexString(), radix: 16)!
        )
    }

}
