import EthereumKit
import GRDB
import BigInt

public class TransactionInfo {
    public let transactionHash: String
    public let transactionIndex: Int?
    public let from: Address
    public let to: Address
    public let value: String
    public let timestamp: TimeInterval
    public let interTransactionIndex: Int

    public var logIndex: Int?
    public var blockHash: String?
    public var blockNumber: Int?

    public var isError: Bool

    init(transaction: Transaction) {
        self.transactionHash = transaction.transactionHash.toHexString()
        self.transactionIndex = transaction.transactionIndex
        self.interTransactionIndex = transaction.interTransactionIndex
        self.logIndex = transaction.logIndex
        self.from = transaction.from
        self.to = transaction.to
        self.value = transaction.value.description
        self.timestamp = transaction.timestamp
        self.blockHash = transaction.blockHash?.toHexString()
        self.blockNumber = transaction.blockNumber
        self.isError = transaction.isError
    }

}
