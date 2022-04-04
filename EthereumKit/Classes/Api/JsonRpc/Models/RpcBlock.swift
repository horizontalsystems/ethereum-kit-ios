import ObjectMapper
import BigInt

public struct RpcBlock: ImmutableMappable {
    public let hash: Data
    public let number: Int
    public let timestamp: Int

    public init(map: Map) throws {
        hash = try map.value("hash", using: HexDataTransform())
        number = try map.value("number", using: HexIntTransform())
        timestamp = try map.value("timestamp", using: HexIntTransform())
    }

}
