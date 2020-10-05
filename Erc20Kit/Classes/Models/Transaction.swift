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

public class Transaction: Record {
    public let transactionHash: Data
    public var transactionIndex: Int?

    public let from: Address
    public let to: Address
    public let value: BigUInt
    public let timestamp: TimeInterval
    public var interTransactionIndex: Int

    public var logIndex: Int?
    public var blockHash: Data?
    public var blockNumber: Int?
    public var isError: Bool
    public var type: TransactionType

    init(transactionHash: Data, transactionIndex: Int? = nil, from: Address, to: Address, value: BigUInt, timestamp: TimeInterval = Date().timeIntervalSince1970, interTransactionIndex: Int = 0, isError: Bool = false, type: TransactionType = .transfer) {
        self.transactionHash = transactionHash
        self.transactionIndex = transactionIndex
        self.from = from
        self.to = to
        self.value = value
        self.timestamp = timestamp
        self.interTransactionIndex = interTransactionIndex
        self.isError = isError
        self.type = type

        super.init()
    }

    public override class var databaseTableName: String {
        "transactions"
    }

    enum Columns: String, ColumnExpression {
        case transactionHash
        case transactionIndex
        case from
        case to
        case value
        case timestamp
        case interTransactionIndex
        case logIndex
        case blockHash
        case blockNumber
        case isError
        case type
    }

    required init(row: Row) {
        transactionHash = row[Columns.transactionHash]
        transactionIndex = row[Columns.transactionIndex]
        from = Address(raw: row[Columns.from])
        to = Address(raw: row[Columns.to])
        value = row[Columns.value]
        timestamp = row[Columns.timestamp]
        interTransactionIndex = row[Columns.interTransactionIndex]
        logIndex = row[Columns.logIndex]
        blockHash = row[Columns.blockHash]
        blockNumber = row[Columns.blockNumber]
        isError = row[Columns.isError]
        type = row[Columns.type]

        super.init(row: row)
    }

    public override func encode(to container: inout PersistenceContainer) {
        container[Columns.transactionHash] = transactionHash
        container[Columns.transactionIndex] = transactionIndex
        container[Columns.from] = from.raw
        container[Columns.to] = to.raw
        container[Columns.value] = value
        container[Columns.timestamp] = timestamp
        container[Columns.interTransactionIndex] = interTransactionIndex
        container[Columns.logIndex] = logIndex
        container[Columns.blockHash] = blockHash
        container[Columns.blockNumber] = blockNumber
        container[Columns.isError] = isError
        container[Columns.type] = type
    }

}
