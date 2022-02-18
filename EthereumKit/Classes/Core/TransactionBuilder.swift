import OpenSslKit
import BigInt

class TransactionBuilder {
    private let chainId: Int
    private let address: Address

    init(network: Network, address: Address) {
        chainId = network.chainId
        self.address = address
    }

    func transaction(rawTransaction: RawTransaction, signature: Signature) -> Transaction {
        let transactionHash = OpenSslKit.Kit.sha3(encode(rawTransaction: rawTransaction, signature: signature))

        var maxFeePerGas: Int? = nil
        var maxPriorityFeePerGas: Int? = nil
        if case .eip1559(let max, let priority) = rawTransaction.gasPrice {
            maxFeePerGas = max
            maxPriorityFeePerGas = priority
        }

        return Transaction(
                hash: transactionHash,
                nonce: rawTransaction.nonce,
                input: rawTransaction.data,
                from: address,
                to: rawTransaction.to,
                value: rawTransaction.value,
                gasLimit: rawTransaction.gasLimit,
                gasPrice: rawTransaction.gasPrice.max,
                maxFeePerGas: maxFeePerGas,
                maxPriorityFeePerGas: maxPriorityFeePerGas
        )
    }

    func encode(rawTransaction: RawTransaction, signature: Signature) -> Data {
        switch rawTransaction.gasPrice {
        case .legacy(let legacyGasPrice):
            return RLP.encode([
                rawTransaction.nonce,
                legacyGasPrice,
                rawTransaction.gasLimit,
                rawTransaction.to.raw,
                rawTransaction.value,
                rawTransaction.data,
                signature.v,
                signature.r,
                signature.s
            ])
        case .eip1559(let maxFeePerGas, let maxPriorityFeePerGas):
            let encodedTransaction = RLP.encode([
                chainId,
                rawTransaction.nonce,
                maxPriorityFeePerGas,
                maxFeePerGas,
                rawTransaction.gasLimit,
                rawTransaction.to.raw,
                rawTransaction.value,
                rawTransaction.data,
                [],
                signature.v,
                signature.r,
                signature.s
            ])

            return Data([0x02]) + encodedTransaction
        }
    }

}
