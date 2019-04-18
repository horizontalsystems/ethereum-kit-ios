import GRDB
import EthereumKit

class TokenBalance: Record {
    let contractAddress: Data
    let value: BInt
    let blockHeight: Int

    init(contractAddress: Data, value: BInt, blockHeight: Int) {
        self.contractAddress = contractAddress
        self.value = value
        self.blockHeight = blockHeight

        super.init()
    }

    override class var databaseTableName: String {
        return "token_balances"
    }

    enum Columns: String, ColumnExpression {
        case contractAddress
        case value
        case blockHeight
    }

    required init(row: Row) {
        contractAddress = row[Columns.contractAddress]
        value = row[Columns.value]
        blockHeight = row[Columns.blockHeight]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.contractAddress] = contractAddress
        container[Columns.value] = value
        container[Columns.blockHeight] = blockHeight
    }

}
