import BigInt
import ObjectMapper

public struct ProviderTransaction: ImmutableMappable {
    let blockNumber: Int
    let timestamp: Int
    let hash: Data
    let nonce: Int
    let blockHash: Data?
    let transactionIndex: Int
    let from: Address
    let to: Address?
    let value: BigUInt
    let gasLimit: Int
    let gasPrice: Int
    let isError: Int?
    let txReceiptStatus: Int?
    let input: Data
    let cumulativeGasUsed: Int?
    let gasUsed: Int?

    public init(map: Map) throws {
        blockNumber = try map.value("blockNumber", using: StringIntTransform())
        timestamp = try map.value("timeStamp", using: StringIntTransform())
        hash = try map.value("hash", using: HexDataTransform())
        nonce = try map.value("nonce", using: StringIntTransform())
        blockHash = try? map.value("blockHash", using: HexDataTransform())
        transactionIndex = try map.value("transactionIndex", using: StringIntTransform())
        from = try map.value("from", using: HexAddressTransform())
        to = try? map.value("to", using: HexAddressTransform())
        value = try map.value("value", using: StringBigUIntTransform())
        gasLimit = try map.value("gas", using: StringIntTransform())
        gasPrice = try map.value("gasPrice", using: StringIntTransform())
        isError = try? map.value("isError", using: StringIntTransform())
        txReceiptStatus = try? map.value("txreceipt_status", using: StringIntTransform())
        input = try map.value("input", using: HexDataTransform())
        cumulativeGasUsed = try? map.value("cumulativeGasUsed", using: StringIntTransform())
        gasUsed = try? map.value("gasUsed", using: StringIntTransform())
    }

}
