import GRDB
import BigInt
import EthereumKit

public enum TransactionType: String, DatabaseValueConvertible {
    case transfer = "transfer"
    case approve = "approve"

    public var databaseValue: DatabaseValue {
        self.rawValue.databaseValue
    }

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> TransactionType? {
        if case let DatabaseValue.Storage.string(value) = dbValue.storage {
            return TransactionType(rawValue: value)
        }

        return nil
    }

}

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
