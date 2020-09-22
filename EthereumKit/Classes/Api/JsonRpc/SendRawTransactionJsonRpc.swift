import Foundation

class SendRawTransactionJsonRpc: DataJsonRpc {

    init(signedTransaction: Data) {
        super.init(
                method: "eth_sendRawTransaction",
                params: [signedTransaction.toHexString()]
        )
    }

}
