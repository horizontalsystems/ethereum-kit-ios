class SendTransactionTask: ITask {
    let sendId: Int
    let rawTransaction: RawTransaction
    let nonce: Int
    let signature: Signature

    init(sendId: Int, rawTransaction: RawTransaction, nonce: Int, signature: Signature) {
        self.sendId = sendId
        self.rawTransaction = rawTransaction
        self.nonce = nonce
        self.signature = signature
    }

}
