import GRDB
import BigInt

class NotSyncedTransactionRecord: Record {
    let hash: Data
    let timestamp: Int?
    let nonce: Int?
    let blockHash: Data?
    let blockNumber: Int?
    let transactionIndex: Int?
    let from: Address?
    let to: Address?
    let value: BigUInt?
    let gasPrice: Int?
    let gasLimit: Int?
    let input: Data?


    init(hash: Data, notSyncedTransaction: NotSyncedTransaction, timestamp: Int? = nil) {
        self.hash = hash
        self.timestamp = timestamp
        nonce = notSyncedTransaction.transaction?.nonce
        blockHash = notSyncedTransaction.transaction?.blockHash
        blockNumber = notSyncedTransaction.transaction?.blockNumber
        transactionIndex = notSyncedTransaction.transaction?.transactionIndex
        from = notSyncedTransaction.transaction?.from
        to = notSyncedTransaction.transaction?.to
        value = notSyncedTransaction.transaction?.value
        gasPrice = notSyncedTransaction.transaction?.gasPrice
        gasLimit = notSyncedTransaction.transaction?.gasLimit
        input = notSyncedTransaction.transaction?.input

        super.init()
    }

    override public class var databaseTableName: String {
        "not_synced_transactions"
    }

    enum Columns: String, ColumnExpression {
        case hash
        case timestamp
        case nonce
        case blockHash
        case blockNumber
        case transactionIndex
        case from
        case to
        case value
        case gasPrice
        case gasLimit
        case input
    }

    required init(row: Row) {
        hash = row[Columns.hash]
        timestamp = row[Columns.timestamp]
        nonce = row[Columns.nonce]
        blockHash = row[Columns.blockHash]
        blockNumber = row[Columns.blockNumber]
        transactionIndex = row[Columns.transactionIndex]
        from = Address(raw: row[Columns.from])
        to = Address(raw: row[Columns.to])
        value = row[Columns.value]
        gasPrice = row[Columns.gasPrice]
        gasLimit = row[Columns.gasLimit]
        input = row[Columns.input]

        super.init(row: row)
    }

    override public func encode(to container: inout PersistenceContainer) {
        container[Columns.hash] = hash
        container[Columns.timestamp] = timestamp
        container[Columns.nonce] = nonce
        container[Columns.blockHash] = blockHash
        container[Columns.blockNumber] = blockNumber
        container[Columns.transactionIndex] = transactionIndex
        container[Columns.from] = from?.raw
        container[Columns.to] = to?.raw
        container[Columns.value] = value
        container[Columns.gasPrice] = gasPrice
        container[Columns.gasLimit] = gasLimit
        container[Columns.input] = input
    }

}
