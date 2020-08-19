import Foundation
import GRDB
import BigInt

public class Transaction: Record {
    static let internalTransactions = hasMany(InternalTransaction.self)

    public let hash: Data
    public let nonce: Int
    public let input: Data
    public let from: Address
    public let to: Address
    public let value: BigUInt
    public let gasLimit: Int
    public let gasPrice: Int
    public let timestamp: TimeInterval

    public var blockHash: Data?
    public var blockNumber: Int?
    public var gasUsed: Int?
    public var cumulativeGasUsed: Int?
    public var isError: Int?
    public var transactionIndex: Int?
    public var txReceiptStatus: Int?

    init(hash: Data, nonce: Int, input: Data = Data(), from: Address, to: Address, value: BigUInt, gasLimit: Int, gasPrice: Int, timestamp: TimeInterval = Date().timeIntervalSince1970) {
        self.hash = hash
        self.nonce = nonce
        self.input = input
        self.from = from
        self.to = to
        self.value = value
        self.gasLimit = gasLimit
        self.gasPrice = gasPrice
        self.timestamp = timestamp

        super.init()
    }

    public override class var databaseTableName: String {
        "transactions"
    }

    enum Columns: String, ColumnExpression {
        case hash
        case nonce
        case input
        case from
        case to
        case value
        case gasLimit
        case gasPrice
        case timestamp
        case blockHash
        case blockNumber
        case gasUsed
        case cumulativeGasUsed
        case isError
        case transactionIndex
        case txReceiptStatus
    }

    required init(row: Row) {
        hash = row[Columns.hash]
        nonce = row[Columns.nonce]
        input = row[Columns.input]
        from = Address(raw: row[Columns.from])
        to = Address(raw: row[Columns.to])
        value = row[Columns.value]
        gasLimit = row[Columns.gasLimit]
        gasPrice = row[Columns.gasPrice]
        timestamp = row[Columns.timestamp]
        blockHash = row[Columns.blockHash]
        blockNumber = row[Columns.blockNumber]
        gasUsed = row[Columns.gasUsed]
        cumulativeGasUsed = row[Columns.cumulativeGasUsed]
        isError = row[Columns.isError]
        transactionIndex = row[Columns.transactionIndex]
        txReceiptStatus = row[Columns.txReceiptStatus]

        super.init(row: row)
    }

    public override func encode(to container: inout PersistenceContainer) {
        container[Columns.hash] = hash
        container[Columns.nonce] = nonce
        container[Columns.input] = input
        container[Columns.from] = from.raw
        container[Columns.to] = to.raw
        container[Columns.value] = value
        container[Columns.gasLimit] = gasLimit
        container[Columns.gasPrice] = gasPrice
        container[Columns.timestamp] = timestamp
        container[Columns.blockHash] = blockHash
        container[Columns.blockNumber] = blockNumber
        container[Columns.gasUsed] = gasUsed
        container[Columns.cumulativeGasUsed] = cumulativeGasUsed
        container[Columns.isError] = isError
        container[Columns.transactionIndex] = transactionIndex
        container[Columns.txReceiptStatus] = txReceiptStatus
    }

}

public struct TransactionWithInternal: FetchableRecord {
    public let transaction: Transaction
    public let internalTransactions: [InternalTransaction]

    public init(row: Row) {
        transaction = Transaction(row: row)
        internalTransactions = row[InternalTransaction.databaseTableName]
    }

    init(transaction: Transaction) {
        self.transaction = transaction
        internalTransactions = []
    }

    init(transaction: Transaction, internalTransactions: [InternalTransaction]) {
        self.transaction = transaction
        self.internalTransactions = internalTransactions
    }

}
