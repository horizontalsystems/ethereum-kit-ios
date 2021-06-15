import GRDB
import BigInt

public class NotSyncedTransaction: Record {
    let hash: Data
    var transaction: RpcTransaction?
    let timestamp: Int?

    public init(hash: Data, transaction: RpcTransaction? = nil, timestamp: Int? = nil) {
        self.hash = hash
        self.transaction = transaction
        self.timestamp = timestamp

        super.init()
    }

    public override class var databaseTableName: String {
        "not_synced_transactions"
    }

    enum Columns: String, ColumnExpression {
        case hash
        case nonce
        case from
        case to
        case value
        case gasPrice
        case gasLimit
        case input
        case blockHash
        case blockNumber
        case transactionIndex
        case timestamp
    }

    required init(row: Row) {
        hash = row[Columns.hash]

        if let nonce = Int.fromDatabaseValue(row[Columns.nonce]),
           let from = Data.fromDatabaseValue(row[Columns.from]).map({ Address(raw: $0) }),
           let to = Data.fromDatabaseValue(row[Columns.to]).map({ Address(raw: $0) }),
           let value = BigUInt.fromDatabaseValue(row[Columns.value]),
           let gasPrice = Int.fromDatabaseValue(row[Columns.gasPrice]),
           let gasLimit = Int.fromDatabaseValue(row[Columns.gasLimit]),
           let input = Data.fromDatabaseValue(row[Columns.input]) {
               transaction = RpcTransaction(
                       hash: hash, nonce: nonce, from: from, to: to, value: value, gasPrice: gasPrice, gasLimit: gasLimit, input: input,
                       blockHash: row[Columns.blockHash], blockNumber: row[Columns.blockNumber], transactionIndex: row[Columns.transactionIndex]
               )
        } else {
            transaction = nil
        }

        timestamp = row[Columns.timestamp]

        super.init(row: row)
    }

    public override func encode(to container: inout PersistenceContainer) {
        container[Columns.hash] = hash
        container[Columns.nonce] = transaction?.nonce
        container[Columns.from] = transaction?.from.raw
        container[Columns.to] = transaction?.to?.raw
        container[Columns.value] = transaction?.value
        container[Columns.gasPrice] = transaction?.gasPrice
        container[Columns.gasLimit] = transaction?.gasLimit
        container[Columns.input] = transaction?.input
        container[Columns.blockHash] = transaction?.blockHash
        container[Columns.blockNumber] = transaction?.blockNumber
        container[Columns.transactionIndex] = transaction?.transactionIndex
        container[Columns.timestamp] = timestamp
    }

}
