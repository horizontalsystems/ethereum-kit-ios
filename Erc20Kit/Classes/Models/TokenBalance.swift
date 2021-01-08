import GRDB
import BigInt

class TokenBalance: Record {
    let primaryKey: String = "primaryKey"
    let value: BigUInt?

    init(value: BigUInt?) {
        self.value = value

        super.init()
    }

    override class var databaseTableName: String {
        "token_balances"
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
