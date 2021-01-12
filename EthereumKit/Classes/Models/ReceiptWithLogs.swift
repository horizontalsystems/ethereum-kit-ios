import GRDB

public struct ReceiptWithLogs: FetchableRecord {
    public let receipt: TransactionReceipt
    public let logs: [TransactionLog]

    public init(row: Row) {
        receipt = TransactionReceipt(row: row)
        logs = row[TransactionLog.databaseTableName]
    }

}
