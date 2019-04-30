import GRDB
import BigInt
import EthereumKit

class Transaction: Record {
    let transactionHash: Data
    var transactionIndex: Int?

    let from: Data
    let to: Data
    let value: BigUInt
    let timestamp: TimeInterval
    let interTransactionIndex: Int

    var logIndex: Int?
    var blockHash: Data?
    var blockNumber: Int?

    init(transactionHash: Data, transactionIndex: Int? = nil, from: Data, to: Data, value: BigUInt, timestamp: TimeInterval = Date().timeIntervalSince1970, interTransactionIndex: Int = 0) {
        self.transactionHash = transactionHash
        self.transactionIndex = transactionIndex
        self.from = from
        self.to = to
        self.value = value
        self.timestamp = timestamp
        self.interTransactionIndex = interTransactionIndex

        super.init()
    }

    override class var databaseTableName: String {
        return "transactions"
    }

    enum Columns: String, ColumnExpression {
        case transactionHash
        case transactionIndex
        case from
        case to
        case value
        case timestamp
        case interTransactionIndex
        case logIndex
        case blockHash
        case blockNumber
    }

    required init(row: Row) {
        transactionHash = row[Columns.transactionHash]
        transactionIndex = row[Columns.transactionIndex]
        from = row[Columns.from]
        to = row[Columns.to]
        value = row[Columns.value]
        timestamp = row[Columns.timestamp]
        interTransactionIndex = row[Columns.interTransactionIndex]
        logIndex = row[Columns.logIndex]
        blockHash = row[Columns.blockHash]
        blockNumber = row[Columns.blockNumber]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.transactionHash] = transactionHash
        container[Columns.transactionIndex] = transactionIndex
        container[Columns.from] = from
        container[Columns.to] = to
        container[Columns.value] = value
        container[Columns.timestamp] = timestamp
        container[Columns.interTransactionIndex] = interTransactionIndex
        container[Columns.logIndex] = logIndex
        container[Columns.blockHash] = blockHash
        container[Columns.blockNumber] = blockNumber
    }

}
