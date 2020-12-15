import GRDB

class TransactionSyncerState: Record {
    let id: String
    let lastBlockNumber: Int

    init(id: String, lastBlockNumber: Int) {
        self.id = id
        self.lastBlockNumber = lastBlockNumber

        super.init()
    }

    public override class var databaseTableName: String {
        "transaction_syncer_states"
    }

    enum Columns: String, ColumnExpression {
        case id
        case lastBlockNumber
    }

    required init(row: Row) {
        id = row[Columns.id]
        lastBlockNumber = row[Columns.lastBlockNumber]

        super.init(row: row)
    }

    public override func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.lastBlockNumber] = lastBlockNumber
    }

}
