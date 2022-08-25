import BigInt
import ObjectMapper

public struct ProviderInternalTransaction: ImmutableMappable {
    let hash: Data
    let blockNumber: Int
    let timestamp: Int
    let from: Address
    let to: Address
    let value: BigUInt
    let traceId: String

    public init(map: Map) throws {
        hash = try map.value("hash", using: HexDataTransform())
        blockNumber = try map.value("blockNumber", using: StringIntTransform())
        timestamp = try map.value("timeStamp", using: StringIntTransform())
        from = try map.value("from", using: HexAddressTransform())
        to = try map.value("to", using: HexAddressTransform())
        value = try map.value("value", using: StringBigUIntTransform())
        traceId = try map.value("traceId")
    }

    var internalTransaction: InternalTransaction {
        InternalTransaction(
                hash: hash,
                blockNumber: blockNumber,
                from: from,
                to: to,
                value: value,
                traceId: traceId
        )
    }

}
