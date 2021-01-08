import GRDB
import BigInt
import EthereumKit

public class Transaction {
    public let hash: Data
    public var interTransactionIndex: Int
    public var transactionIndex: Int?

    public let from: Address
    public let to: Address
    public let value: BigUInt
    public let timestamp: Int

    public var isError: Bool
    public var type: TransactionType
    public var fullTransaction: FullTransaction

    init(hash: Data, interTransactionIndex: Int, transactionIndex: Int? = nil, from: Address, to: Address, value: BigUInt,
         timestamp: Int = Int(Date().timeIntervalSince1970),
         isError: Bool = false, type: TransactionType = .transfer, fullTransaction: FullTransaction) {
        self.hash = hash
        self.interTransactionIndex = interTransactionIndex
        self.transactionIndex = transactionIndex
        self.from = from
        self.to = to
        self.value = value
        self.timestamp = timestamp
        self.isError = isError
        self.type = type
        self.fullTransaction = fullTransaction
    }

}
