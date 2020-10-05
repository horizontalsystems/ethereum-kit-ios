import OpenSslKit
import BigInt

class TransactionBuilder {
    private let address: Address

    init(address: Address) {
        self.address = address
    }

    func rawTransaction(gasPrice: Int, gasLimit: Int, to: Address, value: BigUInt, data: Data = Data(), nonce: Int) -> RawTransaction {
        RawTransaction(gasPrice: gasPrice, gasLimit: gasLimit, to: to, value: value, data: data, nonce: nonce)
    }

    func transaction(rawTransaction: RawTransaction, signature: Signature) -> Transaction {
        let transactionHash = OpenSslKit.Kit.sha3(encode(rawTransaction: rawTransaction, signature: signature))

        return Transaction(
                hash: transactionHash,
                nonce: rawTransaction.nonce,
                input: rawTransaction.data,
                from: address,
                to: rawTransaction.to,
                value: rawTransaction.value,
                gasLimit: rawTransaction.gasLimit,
                gasPrice: rawTransaction.gasPrice
        )
    }

    func encode(rawTransaction: RawTransaction, signature: Signature) -> Data {
        RLP.encode([
            rawTransaction.nonce,
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
