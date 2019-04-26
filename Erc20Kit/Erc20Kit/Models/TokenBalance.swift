import GRDB
import EthereumKit

class TokenBalance: Record {
    let primaryKey: String = "primaryKey"
    let value: BInt?

    init(value: BInt?) {
        self.value = value

        super.init()
    }

    override class var databaseTableName: String {
        return "token_balances"
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
