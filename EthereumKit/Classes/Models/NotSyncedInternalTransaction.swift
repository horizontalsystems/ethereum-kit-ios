import GRDB
import BigInt

/*
 NotSyncedInternalTransaction holds a hash of transactions for which internal transactions need to be synced.
 These internal transactions may not be related to the user's address and they are needed to learn about the
 transactions' final state.

*/

public class NotSyncedInternalTransaction: Record {
    let hash: Data
    var retryCount: Int

    public init(hash: Data, retryCount: Int) {
        self.hash = hash
        self.retryCount = retryCount

        super.init()
    }

    public override class var databaseTableName: String {
        "not_synced_internal_transactions"
    }

    enum Columns: String, ColumnExpression {
        case hash, retryCount
    }

    required init(row: Row) {
        hash = row[Columns.hash]
        retryCount = row[Columns.retryCount]

        super.init(row: row)
    }

    public override func encode(to container: inout PersistenceContainer) {
        container[Columns.hash] = hash
        container[Columns.retryCount] = retryCount
    }

}
