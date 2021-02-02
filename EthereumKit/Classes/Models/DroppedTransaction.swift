import GRDB

public class DroppedTransaction: Record {
    let hash: Data
    var replacedWith: Data

    public init(hash: Data, replacedWith: Data) {
        self.hash = hash
        self.replacedWith = replacedWith

        super.init()
    }

    public override class var databaseTableName: String {
        "dropped_transactions"
    }

    enum Columns: String, ColumnExpression {
        case hash
        case replacedWith
    }

    required init(row: Row) {
        hash = row[Columns.hash]
        replacedWith = row[Columns.replacedWith]

        super.init(row: row)
    }

    public override func encode(to container: inout PersistenceContainer) {
        container[Columns.hash] = hash
        container[Columns.replacedWith] = replacedWith
    }

}
