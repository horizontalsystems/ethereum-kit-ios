import ObjectMapper

public class EthereumLog: ImmutableMappable {
    public let address: Address
    public var blockHash: Data?
    public var blockNumber: Int?
    public let data: Data
    public var logIndex: Int?
    public let removed: Bool
    public let topics: [Data]
    public var transactionHash: Data?
    public var transactionIndex: Int?

    public required init(map: Map) throws {
        address = try map.value("address", using: HexAddressTransform())
        blockHash = try? map.value("blockHash", using: HexDataTransform())
        blockNumber = try? map.value("blockNumber", using: HexIntTransform())
        data = try map.value("data", using: HexDataTransform())
        logIndex = try? map.value("logIndex", using: HexIntTransform())
        removed = try map.value("removed")
        topics = try map.value("topics", using: HexDataTransform())
        transactionHash = try? map.value("transactionHash", using: HexDataTransform())
        transactionIndex = try? map.value("transactionIndex", using: HexIntTransform())
    }

}

extension EthereumLog: Equatable {

    public static func ==(lhs: EthereumLog, rhs: EthereumLog) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

}

extension EthereumLog: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(transactionHash)
        hasher.combine(logIndex)
    }

}

extension EthereumLog: CustomStringConvertible {

    public var description: String {
        "[address: \(address.hex); blockHash: \(blockHash?.hex ?? "nil"); blockNumber: \(blockNumber.map { "\($0)" } ?? "nil"); data: \(data.hex); logIndex: \(logIndex.map { "\($0)" } ?? "nil"); removed: \(removed); topics: \(topics.map { $0.hex }.joined(separator: ", ")); transactionHash: \(transactionHash?.hex ?? "nil"); transactionIndex: \(transactionIndex.map { "\($0)" } ?? "nil")]"
    }

}
