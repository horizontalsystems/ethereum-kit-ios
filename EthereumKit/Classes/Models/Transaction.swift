import Foundation
import GRDB
import BigInt

public class Transaction: Record {
    static let receipt = hasOne(TransactionReceipt.self, using: TransactionReceipt.transactionForeignKey)
    static let internalTransactions = hasMany(InternalTransaction.self)
    static let droppedTransaction = hasOne(DroppedTransaction.self, using: DroppedTransaction.transactionForeignKey)

    var receipt: QueryInterfaceRequest<TransactionReceipt> {
        request(for: Transaction.receipt)
    }

    public let hash: Data
    public let nonce: Int
    public let from: Address
    public var to: Address?
    public let value: BigUInt
    public let gasPrice: Int
    public let gasLimit: Int
    public let input: Data

    public var timestamp: Int

    public init(hash: Data, nonce: Int, input: Data = Data(), from: Address, to: Address?, value: BigUInt, gasLimit: Int, gasPrice: Int, timestamp: Int = Int(Date().timeIntervalSince1970)) {
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

    enum Columns: String, ColumnExpression, CaseIterable {
        case hash
        case nonce
        case input
        case from
        case to
        case value
        case gasLimit
        case gasPrice
        case timestamp
    }

    required init(row: Row) {
        hash = row[Columns.hash]
        nonce = row[Columns.nonce]
        input = row[Columns.input]
        from = Address(raw: row[Columns.from])
        to = row[Columns.to].map { Address(raw: $0) }
        value = row[Columns.value]
        gasLimit = row[Columns.gasLimit]
        gasPrice = row[Columns.gasPrice]
        timestamp = row[Columns.timestamp]

        super.init(row: row)
    }

    public override func encode(to container: inout PersistenceContainer) {
        container[Columns.hash] = hash
        container[Columns.nonce] = nonce
        container[Columns.input] = input
        container[Columns.from] = from.raw
        container[Columns.to] = to?.raw
        container[Columns.value] = value
        container[Columns.gasLimit] = gasLimit
        container[Columns.gasPrice] = gasPrice
        container[Columns.timestamp] = timestamp
    }

}
