import GRDB

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

    public let contractAddress: String?

    init(transaction: Transaction) {
        hash = transaction.hash.toHexString()
        nonce = transaction.nonce
        input = transaction.input.toHexString()
        from = transaction.from.toEIP55Address()
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

        let data = transaction.input

        if data.count == 68 && data[0...3].toRawHexString() == "a9059cbb" {
            to = data[4...35].toEIP55Address()
            value = BInt(number: data[36...67].toRawHexString(), withBase: 16)!.asString(withBase: 10)
            contractAddress = transaction.to.toEIP55Address()
        } else {
            to = transaction.to.toEIP55Address()
            value = transaction.value.asString(withBase: 10)
            contractAddress = nil
        }
    }

}
