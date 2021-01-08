import EthereumKit
import BigInt
import GRDB

class TransactionCache: Record {
    let hash: Data
    var interTransactionIndex: Int
    let logIndex: Int?
    let from: Address
    let to: Address
    let value: BigUInt
    let timestamp: Int
    let type: TransactionType

    init(hash: Data, interTransactionIndex: Int, logIndex: Int?, from: Address, to: Address, value: BigUInt, timestamp: Int, type: TransactionType) {
        self.hash = hash
        self.interTransactionIndex = interTransactionIndex
        self.logIndex = logIndex
        self.from = from
        self.to = to
        self.value = value
        self.timestamp = timestamp
        self.type = type

        super.init()
    }

    public override class var databaseTableName: String {
        "transactions"
    }

    enum Columns: String, ColumnExpression {
        case hash
        case interTransactionIndex
        case logIndex
        case from
        case to
        case value
        case timestamp
        case type
    }

    required init(row: Row) {
        hash = row[Columns.hash]
        interTransactionIndex = row[Columns.interTransactionIndex]
        logIndex = row[Columns.logIndex]
        from = Address(raw: row[Columns.from])
        to = Address(raw: row[Columns.to])
        value = row[Columns.value]
        timestamp = row[Columns.timestamp]
        type = row[Columns.type]

        super.init(row: row)
    }

    public override func encode(to container: inout PersistenceContainer) {
        container[Columns.hash] = hash
        container[Columns.interTransactionIndex] = interTransactionIndex
        container[Columns.logIndex] = logIndex
        container[Columns.from] = from.raw
        container[Columns.to] = to.raw
        container[Columns.value] = value
        container[Columns.timestamp] = timestamp
        container[Columns.type] = type
    }

}
