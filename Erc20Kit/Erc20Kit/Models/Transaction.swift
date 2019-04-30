import GRDB
import BigInt
import EthereumKit

class Transaction: Record {
    var transactionHash: Data

    let from: Data
    let to: Data
    let value: BigUInt
    let timestamp: TimeInterval
    let index: Int

    var logIndex: Int?
    var blockHash: Data?
    var blockNumber: Int?

    init(transactionHash: Data, from: Data, to: Data, value: BigUInt, timestamp: TimeInterval = Date().timeIntervalSince1970, index: Int = 0) {
        self.transactionHash = transactionHash
        self.from = from
        self.to = to
        self.value = value
        self.timestamp = timestamp
        self.index = index

        super.init()
    }

    override class var databaseTableName: String {
        return "transactions"
    }

    enum Columns: String, ColumnExpression {
        case transactionHash
        case from
        case to
        case value
        case timestamp
        case index
        case logIndex
        case blockHash
        case blockNumber
    }

    required init(row: Row) {
        transactionHash = row[Columns.transactionHash]
        from = row[Columns.from]
        to = row[Columns.to]
        value = row[Columns.value]
        timestamp = row[Columns.timestamp]
        index = row[Columns.index]
        logIndex = row[Columns.logIndex]
        blockHash = row[Columns.blockHash]
        blockNumber = row[Columns.blockNumber]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.transactionHash] = transactionHash
        container[Columns.from] = from
        container[Columns.to] = to
        container[Columns.value] = value
        container[Columns.timestamp] = timestamp
        container[Columns.index] = index
        container[Columns.logIndex] = logIndex
        container[Columns.blockHash] = blockHash
        container[Columns.blockNumber] = blockNumber
    }

}
