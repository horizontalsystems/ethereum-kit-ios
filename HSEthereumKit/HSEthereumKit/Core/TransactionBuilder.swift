import HSCryptoKit

class TransactionBuilder {

    func rawTransaction(gasPrice: Int, gasLimit: Int, to: Data, value: BInt) -> RawTransaction {
        return RawTransaction(gasPrice: gasPrice, gasLimit: gasLimit, to: to, value: value)
    }

    func transaction(rawTransaction: RawTransaction, nonce: Int, signature: Signature, address: Data) -> Transaction {
        let transactionHash = CryptoKit.sha3(encode(rawTransaction: rawTransaction, signature: signature, nonce: nonce))

        return Transaction(
                hash: transactionHash,
                nonce: nonce,
                input: rawTransaction.data,
                from: address,
                to: rawTransaction.to,
                value: rawTransaction.value,
                gasLimit: rawTransaction.gasLimit,
                gasPrice: rawTransaction.gasPrice
        )
    }

    func encode(rawTransaction: RawTransaction, signature: Signature, nonce: Int) -> Data {
        return RLP.encode([
            nonce,
            rawTransaction.gasPrice,
            rawTransaction.gasLimit,
            rawTransaction.to,
            rawTransaction.value,
            rawTransaction.data,
            signature.v,
            signature.r,
            signature.s
        ])
    }

}
