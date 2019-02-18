import Foundation
import GRDB

class BlockchainState: Record {
    private static let primaryKey = "primaryKey"

    private let primaryKey: String = BlockchainState.primaryKey
    var lastBlockHeight: Int?
    var gasPrice: Decimal?

    override init() {
        super.init()
    }

    override class var databaseTableName: String {
        return "blockchainStates"
    }

    enum Columns: String, ColumnExpression {
        case primaryKey
        case lastBlockHeight
        case gasPrice
    }

    required init(row: Row) {
        lastBlockHeight = row[Columns.lastBlockHeight]
        gasPrice = row[Columns.gasPrice].flatMap { Decimal(string: $0) }

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.primaryKey] = primaryKey
        container[Columns.lastBlockHeight] = lastBlockHeight
        container[Columns.gasPrice] = gasPrice.map { NSDecimalNumber(decimal: $0).stringValue }
    }

}
