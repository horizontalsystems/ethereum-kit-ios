class SendTransactionMessage: IOutMessage {
    var requestId = 0
    var transaction: Transaction

    init(transaction: Transaction) {
        self.transaction = transaction
    }

    func encoded() -> Data {
        return Data()
    }

    func toString() -> String {
        return "SEND_TX []"
    }

}
