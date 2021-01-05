import GRDB

public struct FullTransaction {
    public let transaction: Transaction
    public let receiptWithLogs: ReceiptWithLogs?
    public let internalTransactions: [InternalTransaction]

    init(transaction: Transaction, receiptWithLogs: ReceiptWithLogs? = nil, internalTransactions: [InternalTransaction] = []) {
        self.transaction = transaction
        self.receiptWithLogs = receiptWithLogs
        self.internalTransactions = internalTransactions
    }

    public var failed: Bool {
        if let receipt = receiptWithLogs?.receipt {
            if let status = receipt.status {
                return status == 0
            } else {
                return transaction.gasLimit == receipt.cumulativeGasUsed
            }
        } else {
            return false
        }
    }

}

public struct ReceiptWithLogs: FetchableRecord {
    public let receipt: TransactionReceipt
    public let logs: [TransactionLog]

    public init(row: Row) {
        receipt = TransactionReceipt(row: row)
        logs = row[TransactionLog.databaseTableName]
    }

}
