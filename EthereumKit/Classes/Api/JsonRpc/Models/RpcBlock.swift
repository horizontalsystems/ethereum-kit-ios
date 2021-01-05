import ObjectMapper
import BigInt

struct RpcBlock: ImmutableMappable {
    let hash: Data
    let number: Int
    let timestamp: Int

    init(map: Map) throws {
        hash = try map.value("hash", using: HexDataTransform())
        number = try map.value("number", using: HexIntTransform())
        timestamp = try map.value("timestamp", using: HexIntTransform())
    }

}
