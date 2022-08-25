import BigInt
import ObjectMapper

public struct ProviderTokenTransaction: ImmutableMappable {
    public let blockNumber: Int
    public let timestamp: Int
    public let hash: Data
    public let nonce: Int
    public let blockHash: Data
    public let from: Address
    public let contractAddress: Address
    public let to: Address
    public let value: BigUInt
    public let tokenName: String
    public let tokenSymbol: String
    public let tokenDecimal: Int
    public let transactionIndex: Int
    public let gasLimit: Int
    public let gasPrice: Int
    public let gasUsed: Int
    public let cumulativeGasUsed: Int

    public init(map: Map) throws {
        blockNumber = try map.value("blockNumber", using: StringIntTransform())
        timestamp = try map.value("timeStamp", using: StringIntTransform())
        hash = try map.value("hash", using: HexDataTransform())
        nonce = try map.value("nonce", using: StringIntTransform())
        blockHash = try map.value("blockHash", using: HexDataTransform())
        from = try map.value("from", using: HexAddressTransform())
        contractAddress = try map.value("contractAddress", using: HexAddressTransform())
        to = try map.value("to", using: HexAddressTransform())
        value = try map.value("value", using: StringBigUIntTransform())
        tokenName = try map.value("tokenName")
        tokenSymbol = try map.value("tokenSymbol")
        tokenDecimal = try map.value("tokenDecimal", using: StringIntTransform())
        transactionIndex = try map.value("transactionIndex", using: StringIntTransform())
        gasLimit = try map.value("gas", using: StringIntTransform())
        gasPrice = try map.value("gasPrice", using: StringIntTransform())
        gasUsed = try map.value("gasUsed", using: StringIntTransform())
        cumulativeGasUsed = try map.value("cumulativeGasUsed", using: StringIntTransform())
    }

}
