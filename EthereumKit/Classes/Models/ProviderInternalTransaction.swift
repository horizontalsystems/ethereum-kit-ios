import BigInt

public struct ProviderInternalTransaction {
    let hash: Data
    let blockNumber: Int
    let timestamp: Int
    let from: Address
    let to: Address
    let value: BigUInt
    let traceId: String
}
