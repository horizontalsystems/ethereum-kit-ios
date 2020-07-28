import OpenSslKit
import BigInt

class TransactionBuilder {
    private let address: Address

    init(address: Address) {
        self.address = address
    }

    func rawTransaction(gasPrice: Int, gasLimit: Int, to: Address, value: BigUInt, data: Data = Data()) -> RawTransaction {
        RawTransaction(gasPrice: gasPrice, gasLimit: gasLimit, to: to, value: value, data: data)
    }

    func transaction(rawTransaction: RawTransaction, nonce: Int, signature: Signature) -> Transaction {
        let transactionHash = OpenSslKit.Kit.sha3(encode(rawTransaction: rawTransaction, signature: signature, nonce: nonce))

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
        RLP.encode([
            nonce,
            rawTransaction.gasPrice,
            rawTransaction.gasLimit,
            rawTransaction.to.raw,
            rawTransaction.value,
            rawTransaction.data,
            signature.v,
            signature.r,
            signature.s
        ])
    }

}
