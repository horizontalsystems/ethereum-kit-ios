import GRDB

public class EthereumTransaction: Record {
    public let hash: String
    public let nonce: Int
    public let input: String
    public let from: String
    public let to: String
    public let amount: String
    public let gasLimit: Int
    public let gasPrice: Int
    public let timestamp: TimeInterval

    public var blockHash: String?
    public var blockNumber: Int?
    public var confirmations: Int?
    public var gasUsed: Int?
    public var cumulativeGasUsed: Int?
    public var isError: Bool?
    public var transactionIndex: Int?
    public var txReceiptStatus: Bool?

    public init(hash: String, nonce: Int, input: String = "0x", from: String, to: String, amount: String, gasLimit: Int, gasPrice: Int, timestamp: TimeInterval? = nil) {
        self.hash = hash
        self.nonce = nonce
        self.input = input
        self.from = from
        self.to = to
        self.amount = amount
        self.gasLimit = gasLimit
        self.gasPrice = gasPrice
        self.timestamp = timestamp ?? Date().timeIntervalSince1970

        super.init()
    }

    override public class var databaseTableName: String {
        return "transactions"
    }

    enum Columns: String, ColumnExpression {
        case hash
        case nonce
        case input
        case from
        case to
        case amount
        case gasLimit
        case gasPrice
        case timestamp
        case blockHash
        case blockNumber
        case confirmations
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
        amount = row[Columns.amount]
        gasLimit = row[Columns.gasLimit]
        gasPrice = row[Columns.gasPrice]
        timestamp = row[Columns.timestamp]
        blockHash = row[Columns.blockHash]
        blockNumber = row[Columns.blockNumber]
        confirmations = row[Columns.confirmations]
        gasUsed = row[Columns.gasUsed]
        cumulativeGasUsed = row[Columns.cumulativeGasUsed]
        isError = row[Columns.isError]
        transactionIndex = row[Columns.transactionIndex]
        txReceiptStatus = row[Columns.txReceiptStatus]

        super.init(row: row)
    }

    override public func encode(to container: inout PersistenceContainer) {
        container[Columns.hash] = hash
        container[Columns.nonce] = nonce
        container[Columns.input] = input
        container[Columns.from] = from
        container[Columns.to] = to
        container[Columns.amount] = amount
        container[Columns.gasLimit] = gasLimit
        container[Columns.gasPrice] = gasPrice
        container[Columns.timestamp] = timestamp
        container[Columns.blockHash] = blockHash
        container[Columns.blockNumber] = blockNumber
        container[Columns.confirmations] = confirmations
        container[Columns.gasUsed] = gasUsed
        container[Columns.cumulativeGasUsed] = cumulativeGasUsed
        container[Columns.isError] = isError
        container[Columns.transactionIndex] = transactionIndex
        container[Columns.txReceiptStatus] = txReceiptStatus
    }

}
