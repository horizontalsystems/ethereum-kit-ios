import GRDB

class Eip20TransactionSyncOrder: Record {
    let contractAddress: String
    let value: Int?

    init(contractAddress: String, value: Int?) {
        self.contractAddress = contractAddress
        self.value = value

        super.init()
    }

    override class var databaseTableName: String {
        "eip_transaction_sync_orders"
    }

    enum Columns: String, ColumnExpression {
        case contractAddress
        case value
    }

    required init(row: Row) {
        contractAddress = row[Columns.contractAddress]
        value = row[Columns.value]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.contractAddress] = contractAddress
        container[Columns.value] = value
    }

}
