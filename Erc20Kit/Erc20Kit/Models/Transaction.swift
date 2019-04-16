import GRDB
import EthereumKit

class Transaction: Record {
    var transactionHash: Data

    let contractAddress: Data
    let from: Data
    let to: Data
    let value: BInt
    var timestamp: TimeInterval

    var logIndex: Int?
    var blockHash: Data?
    var blockNumber: Int?

    init(transactionHash: Data, contractAddress: Data, from: Data, to: Data, value: BInt, timestamp: TimeInterval = Date().timeIntervalSince1970) {
        self.transactionHash = transactionHash
        self.contractAddress = contractAddress
        self.from = from
        self.to = to
        self.value = value
        self.timestamp = timestamp

        super.init()
    }

    override class var databaseTableName: String {
        return "transactions"
    }

    enum Columns: String, ColumnExpression {
        case transactionHash
        case contractAddress
        case from
        case to
        case value
        case timestamp
        case logIndex
        case blockHash
        case blockNumber
    }

    required init(row: Row) {
        transactionHash = row[Columns.transactionHash]
        contractAddress = row[Columns.contractAddress]
        from = row[Columns.from]
        to = row[Columns.to]
        value = row[Columns.value]
        timestamp = row[Columns.timestamp]
        logIndex = row[Columns.logIndex]
        blockHash = row[Columns.blockHash]
        blockNumber = row[Columns.blockNumber]

        super.init(row: row)
    }

    init?(log: EthereumLog) {
        guard log.topics.count == 3,
              log.topics[0] == Erc20Kit.transferEventTopic,
              log.topics[1].count == 32 && log.topics[2].count == 32  else {
            return nil
        }

        self.transactionHash = log.transactionHash

        self.contractAddress = log.address
        self.from = log.topics[1].suffix(from: 12)
        self.to = log.topics[2].suffix(from: 12)
        self.value = BInt(log.data.toHexString(), radix: 16)!
        self.timestamp = log.timestamp ?? Date().timeIntervalSince1970

        self.logIndex = log.logIndex
        self.blockHash = log.blockHash
        self.blockNumber = log.blockNumber


        super.init()
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.transactionHash] = transactionHash
        container[Columns.contractAddress] = contractAddress
        container[Columns.from] = from
        container[Columns.to] = to
        container[Columns.value] = value
        container[Columns.timestamp] = timestamp
        container[Columns.logIndex] = logIndex
        container[Columns.blockHash] = blockHash
        container[Columns.blockNumber] = blockNumber
    }

}
