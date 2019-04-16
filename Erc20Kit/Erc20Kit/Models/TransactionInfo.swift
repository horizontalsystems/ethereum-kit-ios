import GRDB
import EthereumKit

public class TransactionInfo {
    public let transactionHash: String
    public let from: String
    public let to: String
    public let value: String
    public let timestamp: TimeInterval

    public var logIndex: Int?
    public var blockHash: String?
    public var blockNumber: Int?

    init(transaction: Transaction) {
        self.transactionHash = transaction.transactionHash.toHexString()
        self.logIndex = transaction.logIndex
        self.from = transaction.from.toHexString()
        self.to = transaction.to.toHexString()
        self.value = transaction.value.asString(withBase: 10)
        self.timestamp = transaction.timestamp
        self.blockHash = transaction.blockHash?.toHexString()
        self.blockNumber = transaction.blockNumber
    }

    init(hash: String, from: String, to: String, value: String, timestamp: TimeInterval) {
        self.transactionHash = hash
        self.from = from
        self.to = to
        self.value = value
        self.timestamp = timestamp
    }

}
