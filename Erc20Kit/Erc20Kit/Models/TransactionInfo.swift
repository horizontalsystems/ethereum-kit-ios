import GRDB
import BigInt

public class TransactionInfo {
    public let transactionHash: String
    public let from: String
    public let to: String
    public let value: String
    public let timestamp: TimeInterval
    public let index: Int

    public var logIndex: Int?
    public var blockHash: String?
    public var blockNumber: Int?

    init(transaction: Transaction) {
        self.transactionHash = transaction.transactionHash.toHexString()
        self.index = transaction.index
        self.logIndex = transaction.logIndex
        self.from = transaction.from.toEIP55Address()
        self.to = transaction.to.toEIP55Address()
        self.value = transaction.value.description
        self.timestamp = transaction.timestamp
        self.blockHash = transaction.blockHash?.toHexString()
        self.blockNumber = transaction.blockNumber
    }

}
