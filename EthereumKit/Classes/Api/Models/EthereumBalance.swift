import GRDB
import BigInt

class EthereumBalance: Record {
    private static let primaryKey = "primaryKey"

    private let primaryKey: String = EthereumBalance.primaryKey

    let value: BigUInt

    init(value: BigUInt) {
        self.value = value

        super.init()
    }

    override class var databaseTableName: String {
        return "ethereumBalance"
    }

    enum Columns: String, ColumnExpression {
        case primaryKey
        case value
    }

    required init(row: Row) {
        value = row[Columns.value]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.primaryKey] = primaryKey
        container[Columns.value] = value
    }

}
