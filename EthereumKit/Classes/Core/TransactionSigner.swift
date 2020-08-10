import OpenSslKit
import Secp256k1Kit
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
            rawTransaction.to.raw,
            rawTransaction.value,
            rawTransaction.data
        ]

        if chainId != 0 {
            toEncode.append(contentsOf: [chainId, 0, 0 ]) // EIP155
        }

        let encodedData = RLP.encode(toEncode)
        let rawTransactionHash = OpenSslKit.Kit.sha3(encodedData)

        return try Secp256k1Kit.Kit.ellipticSign(rawTransactionHash, privateKey: privateKey)
    }

    func signature(rawTransaction: RawTransaction, nonce: Int) throws -> Signature {
        let signatureData: Data = try sign(rawTransaction: rawTransaction, nonce: nonce)

        return signature(from: signatureData)
    }

    func signature(from data: Data) -> Signature {
        return Signature(
                v: Int(data[64]) + (chainId == 0 ? 27 : (35 + 2 * chainId)),
                r: BigUInt(data[..<32].hex, radix: 16)!,
                s: BigUInt(data[32..<64].hex, radix: 16)!
        )
    }

}
