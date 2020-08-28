import Foundation

class SendRawTransactionJsonRpc: DataJsonRpc {
    let signedTransaction: Data

    init(signedTransaction: Data) {
        self.signedTransaction = signedTransaction

        super.init(
                method: "eth_sendRawTransaction",
                params: [signedTransaction.toHexString()]
        )
    }

}
