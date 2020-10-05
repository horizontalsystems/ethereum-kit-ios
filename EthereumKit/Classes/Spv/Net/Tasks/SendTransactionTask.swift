class SendTransactionTask: ITask {
    let sendId: Int
    let rawTransaction: RawTransaction
    let signature: Signature

    init(sendId: Int, rawTransaction: RawTransaction, signature: Signature) {
        self.sendId = sendId
        self.rawTransaction = rawTransaction
        self.signature = signature
    }

}
