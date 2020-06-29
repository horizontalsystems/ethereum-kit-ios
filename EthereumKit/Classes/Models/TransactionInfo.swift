import BigInt

public class TransactionInfo {
    public let hash: String
    public let nonce: Int
    public let input: String
    public let from: String
    public let to: String
    public let value: String
    public let gasLimit: Int
    public let gasPrice: Int
    public let timestamp: TimeInterval

    public let blockHash: String?
    public let blockNumber: Int?
    public let gasUsed: Int?
    public let cumulativeGasUsed: Int?
    public let isError: Int?
    public let transactionIndex: Int?
    public let txReceiptStatus: Int?

    public let internalTransactions: [InternalTransactionInfo]

    init(transactionWithInternal: TransactionWithInternal) {
        let transaction = transactionWithInternal.transaction

        hash = transaction.hash.toHexString()
        nonce = transaction.nonce
        input = transaction.input.toHexString()
        from = transaction.from.toEIP55Address()
        to = transaction.to.toEIP55Address()
        value = transaction.value.description
        gasLimit = transaction.gasLimit
        gasPrice = transaction.gasPrice
        timestamp = transaction.timestamp

        blockHash = transaction.blockHash?.toHexString()
        blockNumber = transaction.blockNumber
        gasUsed = transaction.gasUsed
        cumulativeGasUsed = transaction.cumulativeGasUsed
        isError = transaction.isError
        transactionIndex = transaction.transactionIndex
        txReceiptStatus = transaction.txReceiptStatus

        internalTransactions = transactionWithInternal.internalTransactions.map { InternalTransactionInfo(transaction: $0) }
    }

}
