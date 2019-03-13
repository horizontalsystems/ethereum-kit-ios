class TransactionStatusMessage: IInMessage {
    var requestId = 0
    var bv: BInt = 0
    var transactionStatuses = [Data: TransactionStatus]()

    required init(data: Data) throws {
    }

    func toString() -> String {
        return "TX_STATUS []"
    }

    enum TransactionStatus: Int {
        case unknown = 0   // transaction is unknown
        case queued = 1    // transaction is queued (not processable yet)
        case pending = 2   // transaction is pending (processable)
        case included = 3  // transaction is already included in the canonical chain. data contains an RLP-encoded [blockHash: B_32, blockNumber: P, txIndex: P] structure
        case error = 4     // transaction sending failed. data contains a text error message
    }

}
