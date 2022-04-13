import BigInt

public struct ProviderInternalTransaction {
    let hash: Data
    let blockNumber: Int
    let timestamp: Int
    let from: Address
    let to: Address
    let value: BigUInt
    let traceId: String

    var internalTransaction: InternalTransaction {
        InternalTransaction(
                hash: hash,
                from: from,
                to: to,
                value: value,
                traceId: traceId
        )
    }

}
