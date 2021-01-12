import GRDB

class TransactionSyncOrder: Record {
    let primaryKey: String = "primaryKey"
    let value: Int?

    init(value: Int?) {
        self.value = value

        super.init()
    }

    override class var databaseTableName: String {
        "transaction_sync_states"
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
