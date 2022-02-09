import ObjectMapper

public struct FeeHistory: ImmutableMappable {
    public let baseFeePerGas: [Int]
    public let gasUsedRatio: [Double]
    public let oldestBlock: Int
    public let reward: [[Int]]

    public init(map: Map) throws {
        baseFeePerGas = try map.value("baseFeePerGas", using: HexIntTransform())
        gasUsedRatio = try map.value("gasUsedRatio")
        oldestBlock = try map.value("oldestBlock", using: HexIntTransform())
        reward = try map.value("reward", using: HexIntTransform())
    }

}
