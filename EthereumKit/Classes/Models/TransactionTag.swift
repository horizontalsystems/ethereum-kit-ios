import GRDB

class TransactionTag: Record {
    let name: String
    let transactionHash: Data

    init(name: String, transactionHash: Data) {
        self.name = name
        self.transactionHash = transactionHash

        super.init()
    }

    public override class var databaseTableName: String {
        "transaction_tags"
    }

    enum Columns: String, ColumnExpression, CaseIterable {
        case name
        case transactionHash
    }

    required init(row: Row) {
        name = row[Columns.name]
        transactionHash = row[Columns.transactionHash]

        super.init(row: row)
    }

    public override func encode(to container: inout PersistenceContainer) {
        container[Columns.name] = name
        container[Columns.transactionHash] = transactionHash
    }

}
