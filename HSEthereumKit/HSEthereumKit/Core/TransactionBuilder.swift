import HSCryptoKit

class TransactionBuilder {

    func rawTransaction(gasPrice: Int, gasLimit: Int, to: Address, value: BInt) -> RawTransaction {
        return RawTransaction(gasPrice: gasPrice, gasLimit: gasLimit, to: to, value: value)
    }

    func rawErc20Transaction(contractAddress: Address, gasPrice: Int, gasLimit: Int, to: Address, value: BInt) -> RawTransaction {
        let data = Data()

        // todo: create data for erc20 transfer

        return RawTransaction(gasPrice: gasPrice, gasLimit: gasLimit, to: contractAddress, value: value, data: data)
    }

    func transaction(rawTransaction: RawTransaction, nonce: Int, signature: Signature, address: Address) -> EthereumTransaction {
        let transactionHash = CryptoKit.sha3(encode(rawTransaction: rawTransaction, signature: signature, nonce: nonce))

        return EthereumTransaction(
                hash: transactionHash.toHexString(),
                nonce: nonce,
                input: "0x" + rawTransaction.data.toHexString(),
                from: address.string,
                to: rawTransaction.to.string,
                amount: rawTransaction.value.asString(withBase: 10),
                gasLimit: rawTransaction.gasLimit,
                gasPrice: rawTransaction.gasPrice
        )
    }

    func encode(rawTransaction: RawTransaction, signature: Signature, nonce: Int) -> Data {
        return RLP.encode([
            nonce,
            rawTransaction.gasPrice,
            rawTransaction.gasLimit,
            rawTransaction.to.data,
            rawTransaction.value,
            rawTransaction.data,
            signature.v,
            signature.r,
            signature.s
        ])
    }

}
