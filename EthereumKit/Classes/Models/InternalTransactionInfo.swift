import BigInt

public class InternalTransactionInfo {
    public let hash: String
    public let from: String
    public let to: String
    public let value: String
    public let traceId: Int

    init(transaction: InternalTransaction) {
        hash = transaction.hash.toHexString()
        from = transaction.from.toEIP55Address()
        to = transaction.to.toEIP55Address()
        value = transaction.value.description
        traceId = transaction.traceId
    }

}
