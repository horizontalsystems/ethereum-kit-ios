import GRDB

class BlockchainState: Record {
    private static let primaryKey = "primaryKey"

    private let primaryKey: String = BlockchainState.primaryKey
    var lastBlockHeight: Int?

    override init() {
        super.init()
    }

    override class var databaseTableName: String {
        return "blockchainStates"
    }

    enum Columns: String, ColumnExpression {
        case primaryKey
        case lastBlockHeight
    }

    required init(row: Row) {
        lastBlockHeight = row[Columns.lastBlockHeight]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.primaryKey] = primaryKey
        container[Columns.lastBlockHeight] = lastBlockHeight
    }

}
