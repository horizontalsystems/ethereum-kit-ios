import GRDB
import BigInt

public class InternalTransaction: Record {
    public let hash: Data
    public let blockNumber: Int
    public let from: Address
    public let to: Address
    public let value: BigUInt
    public let traceId: String

    init(hash: Data, blockNumber: Int, from: Address, to: Address, value: BigUInt, traceId: String) {
        self.hash = hash
        self.blockNumber = blockNumber
        self.from = from
        self.to = to
        self.value = value
        self.traceId = traceId

        super.init()
    }

    override public class var databaseTableName: String {
        "internalTransactions"
    }

    enum Columns: String, ColumnExpression, CaseIterable {
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

    override public func encode(to container: inout PersistenceContainer) {
        container[Columns.hash] = hash
        container[Columns.blockNumber] = blockNumber
        container[Columns.from] = from.raw
        container[Columns.to] = to.raw
        container[Columns.value] = value
        container[Columns.traceId] = traceId
    }

}
