import Foundation
import GRDB

class EthereumBalance: Record {
    let address: String
    let value: String

    init(address: String, value: String) {
        self.address = address
        self.value = value

        super.init()
    }

    override class var databaseTableName: String {
        return "balances"
    }

    enum Columns: String, ColumnExpression {
        case address
        case value
    }

    required init(row: Row) {
        address = row[Columns.address]
        value = row[Columns.value]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.address] = address
        container[Columns.value] = value
    }

}
