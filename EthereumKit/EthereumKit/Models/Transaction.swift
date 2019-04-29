import GRDB
import BigInt

class Transaction: Record {
    let hash: Data
    let nonce: Int
    let input: Data
    let from: Data
    let to: Data
    let value: BigUInt
    let gasLimit: Int
    let gasPrice: Int
    let timestamp: TimeInterval

    var blockHash: Data?
    var blockNumber: Int?
    var gasUsed: Int?
    var cumulativeGasUsed: Int?
    var isError: Int?
    var transactionIndex: Int?
    var txReceiptStatus: Int?

    init(hash: Data, nonce: Int, input: Data = Data(), from: Data, to: Data, value: BigUInt, gasLimit: Int, gasPrice: Int, timestamp: TimeInterval = Date().timeIntervalSince1970) {
        self.hash = hash
        self.nonce = nonce
        self.input = input
        self.from = from
        self.to = to
        self.value = value
        self.gasLimit = gasLimit
        self.gasPrice = gasPrice
        self.timestamp = timestamp

        super.init()
    }

    override class var databaseTableName: String {
        return "transactions"
    }

    enum Columns: String, ColumnExpression {
        case hash
        case nonce
        case input
        case from
        case to
        case value
        case gasLimit
        case gasPrice
        case timestamp
        case blockHash
        case blockNumber
        case gasUsed
        case cumulativeGasUsed
        case isError
        case transactionIndex
        case txReceiptStatus
    }

    required init(row: Row) {
        hash = row[Columns.hash]
        nonce = row[Columns.nonce]
        input = row[Columns.input]
        from = row[Columns.from]
        to = row[Columns.to]
        value = row[Columns.value]
        gasLimit = row[Columns.gasLimit]
        gasPrice = row[Columns.gasPrice]
        timestamp = row[Columns.timestamp]
        blockHash = row[Columns.blockHash]
        blockNumber = row[Columns.blockNumber]
        gasUsed = row[Columns.gasUsed]
        cumulativeGasUsed = row[Columns.cumulativeGasUsed]
        isError = row[Columns.isError]
        transactionIndex = row[Columns.transactionIndex]
        txReceiptStatus = row[Columns.txReceiptStatus]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.hash] = hash
        container[Columns.nonce] = nonce
        container[Columns.input] = input
        container[Columns.from] = from
        container[Columns.to] = to
        container[Columns.value] = value
        container[Columns.gasLimit] = gasLimit
        container[Columns.gasPrice] = gasPrice
        container[Columns.timestamp] = timestamp
        container[Columns.blockHash] = blockHash
        container[Columns.blockNumber] = blockNumber
        container[Columns.gasUsed] = gasUsed
        container[Columns.cumulativeGasUsed] = cumulativeGasUsed
        container[Columns.isError] = isError
        container[Columns.transactionIndex] = transactionIndex
        container[Columns.txReceiptStatus] = txReceiptStatus
    }

}
