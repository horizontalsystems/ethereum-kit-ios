import BigInt

public class InternalTransactionInfo {
    public let hash: String
    public let from: Address
    public let to: Address
    public let value: String
    public let traceId: Int

    init(transaction: InternalTransaction) {
        hash = transaction.hash.toHexString()
        from = transaction.from
        to = transaction.to
        value = transaction.value.description
        traceId = transaction.traceId
    }

}
