import BigInt
import ObjectMapper

public class TransactionLog: ImmutableMappable {
    public let address: Address       // address from which this log originated.
    public var blockHash: Data        // hash of the block where this log was in. null when its pending. null when its pending log.
    public var blockNumber: Int       // the block number where this log was in. null when its pending. null when its pending log.
    public let data: Data             // contains one or more 32 Bytes non-indexed arguments of the log.
    public var logIndex: Int          // integer of the log index position in the block. null when its pending log.
    public let removed: Bool          // true when the log was removed, due to a chain reorganization. false if its a valid log.
    public let topics: [Data]         // Array of 0 to 4 32 Bytes DATA of indexed log arguments.
    public var transactionHash: Data  // hash of the transactions this log was created from. null when its pending log.
    public var transactionIndex: Int  // integer of the transactions index position log was created from. null when its pending log.

    public init(address: Address, blockHash: Data, blockNumber: Int, data: Data, logIndex: Int, removed: Bool, topics: [Data], transactionHash: Data, transactionIndex: Int) {
        self.address = address
        self.blockHash = blockHash
        self.blockNumber = blockNumber
        self.data = data
        self.logIndex = logIndex
        self.removed = removed
        self.topics = topics
        self.transactionHash = transactionHash
        self.transactionIndex = transactionIndex
    }

    public required init(map: Map) throws {
        address = try map.value("address", using: HexAddressTransform())
        blockHash = try map.value("blockHash", using: HexDataTransform())
        blockNumber = try map.value("blockNumber", using: HexIntTransform())
        data = try map.value("data", using: HexDataTransform())
        logIndex = try map.value("logIndex", using: HexIntTransform())
        removed = try map.value("removed")
        topics = try map.value("topics", using: HexDataArrayTransform())
        transactionHash = try map.value("transactionHash", using: HexDataTransform())
        transactionIndex = try map.value("transactionIndex", using: HexIntTransform())
    }

}
