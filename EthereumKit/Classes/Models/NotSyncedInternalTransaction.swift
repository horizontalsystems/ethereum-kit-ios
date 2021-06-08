import GRDB
import BigInt

/*
 NotSyncedInternalTransaction holds a hash of transactions for which internal transactions need to be synced.
 These internal transactions may not be related to the user's address and they are needed to learn about the
 transactions' final state.

*/

public class NotSyncedInternalTransaction: Record {
    let hash: Data

    public init(hash: Data) {
        self.hash = hash

        super.init()
    }

    public override class var databaseTableName: String {
        "not_synced_internal_transactions"
    }

    enum Columns: String, ColumnExpression {
        case hash
    }

    required init(row: Row) {
        hash = row[Columns.hash]

        super.init(row: row)
    }

    public override func encode(to container: inout PersistenceContainer) {
        container[Columns.hash] = hash
    }

}
