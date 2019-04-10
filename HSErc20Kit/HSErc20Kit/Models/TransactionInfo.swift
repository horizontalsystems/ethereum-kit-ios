import GRDB
import HSEthereumKit

public class TransactionInfo {
    public let transactionHash: String
    public var transactionIndex: Int
    public let from: String
    public let to: String
    public let value: String
    public let timestamp: TimeInterval

    public var blockHash: String?
    public var blockNumber: Int?

    init(transaction: Transaction) {
        self.transactionHash = transaction.transactionHash.toHexString()
        self.transactionIndex = transaction.transactionIndex
        self.from = transaction.from.toHexString()
        self.to = transaction.to.toHexString()
        self.value = transaction.value.asString(withBase: 10)
        self.timestamp = transaction.timestamp
        self.blockHash = transaction.blockHash?.toHexString()
        self.blockNumber = transaction.blockNumber
    }

}
