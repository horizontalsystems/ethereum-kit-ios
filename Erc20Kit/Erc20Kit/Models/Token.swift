import GRDB
import EthereumKit

class Token: Record {

    let contractAddress: Data
    let contractBalanceKey: String

    var balance: BInt?
    var syncedBlockHeight: Int?

    init(contractAddress: Data, contractBalanceKey: String, balance: BInt?, syncedBlockHeight: Int?) {
        self.contractAddress = contractAddress
        self.contractBalanceKey = contractBalanceKey
        self.balance = balance
        self.syncedBlockHeight = syncedBlockHeight

        super.init()
    }

    override class var databaseTableName: String {
        return "tokens"
    }

    enum Columns: String, ColumnExpression {
        case contractAddress
        case contractBalanceKey
        case balance
        case syncedBlockHeight
    }

    required init(row: Row) {
        contractAddress = row[Columns.contractAddress]
        contractBalanceKey = row[Columns.contractBalanceKey]
        balance = row[Columns.balance]
        syncedBlockHeight = row[Columns.syncedBlockHeight]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.contractAddress] = contractAddress
        container[Columns.contractBalanceKey] = contractBalanceKey
        container[Columns.balance] = balance
        container[Columns.syncedBlockHeight] = syncedBlockHeight
    }

}
