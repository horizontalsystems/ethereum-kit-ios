import GRDB
import BigInt

class InternalTransaction: Record {
    static let transaction = belongsTo(Transaction.self)

    let hash: Data
    let blockNumber: Int
    let from: Address
    let to: Address
    let value: BigUInt
    let traceId: Int

    init(hash: Data, blockNumber: Int, from: Address, to: Address, value: BigUInt, traceId: Int) {
        self.hash = hash
        self.blockNumber = blockNumber
        self.from = from
        self.to = to
        self.value = value
        self.traceId = traceId

        super.init()
    }

    override class var databaseTableName: String {
        "internal_transactions"
    }

    enum Columns: String, ColumnExpression {
        case hash
        case blockNumber
        case from
        case to
        case value
        case traceId
    }

    required init(row: Row) {
        hash = row[Columns.hash]
        blockNumber = row[Columns.blockNumber]
        from = Address(raw: row[Columns.from])
        to = Address(raw: row[Columns.to])
        value = row[Columns.value]
        traceId = row[Columns.traceId]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.hash] = hash
        container[Columns.blockNumber] = blockNumber
        container[Columns.from] = from.raw
        container[Columns.to] = to.raw
        container[Columns.value] = value
        container[Columns.traceId] = traceId
    }

}
