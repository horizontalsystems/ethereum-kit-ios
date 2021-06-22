import GRDB
import BigInt

class Eip20Balance: Record {
    let contractAddress: String
    let value: BigUInt?

    init(contractAddress: String, value: BigUInt?) {
        self.contractAddress = contractAddress
        self.value = value

        super.init()
    }

    override class var databaseTableName: String {
        "eip20_balances"
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
