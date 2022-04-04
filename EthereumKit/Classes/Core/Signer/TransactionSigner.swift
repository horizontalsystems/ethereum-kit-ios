import OpenSslKit
import Secp256k1Kit
import BigInt

class TransactionSigner {
    private let chainId: Int
    private let privateKey: Data

    init(chain: Chain, privateKey: Data) {
        chainId = chain.id
        self.privateKey = privateKey
    }

    func sign(rawTransaction: RawTransaction) throws -> Data {
        switch rawTransaction.gasPrice {
        case .legacy(let legacyGasPrice):
            return try signEip155(rawTransaction: rawTransaction, legacyGasPrice: legacyGasPrice)
        case .eip1559(let maxFeePerGas, let maxPriorityFeePerGas):
            return try signEip1559(rawTransaction: rawTransaction, maxFeePerGas: maxFeePerGas, maxPriorityFeePerGas: maxPriorityFeePerGas)
        }
    }

    func signEip155(rawTransaction: RawTransaction, legacyGasPrice: Int) throws -> Data {
        var toEncode: [Any] = [
            rawTransaction.nonce,
            legacyGasPrice,
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

    func signEip1559(rawTransaction: RawTransaction, maxFeePerGas: Int, maxPriorityFeePerGas: Int) throws -> Data {
        let toEncode: [Any] = [
            chainId,
            rawTransaction.nonce,
            maxPriorityFeePerGas,
            maxFeePerGas,
            rawTransaction.gasLimit,
            rawTransaction.to.raw,
            rawTransaction.value,
            rawTransaction.data,
            []
        ]

        let encodedData = RLP.encode(toEncode)
        let rawTransactionHash = OpenSslKit.Kit.sha3(Data([0x02]) + encodedData)

        return try Secp256k1Kit.Kit.ellipticSign(rawTransactionHash, privateKey: privateKey)
    }

    func signature(rawTransaction: RawTransaction) throws -> Signature {
        let signatureData: Data = try sign(rawTransaction: rawTransaction)

        switch rawTransaction.gasPrice {
        case .legacy:
            return signatureLegacy(from: signatureData)
        case .eip1559:
            return signatureEip1559(from: signatureData)
        }
    }

    func signatureLegacy(from data: Data) -> Signature {
        Signature(
                v: Int(data[64]) + (chainId == 0 ? 27 : (35 + 2 * chainId)),
                r: BigUInt(data[..<32].hex, radix: 16)!,
                s: BigUInt(data[32..<64].hex, radix: 16)!
        )
    }

    func signatureEip1559(from data: Data) -> Signature {
        Signature(
                v: Int(data[64]),
                r: BigUInt(data[..<32].hex, radix: 16)!,
                s: BigUInt(data[32..<64].hex, radix: 16)!
        )
    }

}
