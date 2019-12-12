public class EthereumLog {

    public let address: Data
    public let blockHash: Data
    public let blockNumber: Int
    public let data: Data
    public let logIndex: Int
    public let removed: Bool
    public let topics: [Data]
    public let transactionHash: Data
    public let transactionIndex: Int

    public var timestamp: TimeInterval?

    init(address: Data, blockHash: Data, blockNumber: Int, data: Data, logIndex: Int, removed: Bool, topics: [Data], transactionHash: Data, transactionIndex: Int) {
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

    init?(json: Any) {
        guard let log = json as? [String: Any] else {
            return nil
        }

        guard let addressStr = log["address"] as? String, let address = Data(hex: addressStr),
              let blockHashStr = log["blockHash"] as? String, let blockHash = Data(hex: blockHashStr),
              let blockNumberStr = log["blockNumber"] as? String, let blockNumber = Int(blockNumberStr.stripHexPrefix(), radix: 16),
              let dataStr = log["data"] as? String, let data = Data(hex: dataStr),
              let logIndexStr = log["logIndex"] as? String, let logIndex = Int(logIndexStr.stripHexPrefix(), radix: 16),
              let removed = log["removed"] as? Bool,
              let topics = log["topics"] as? [String],
              let transactionHashStr = log["transactionHash"] as? String, let transactionHash = Data(hex: transactionHashStr),
              let transactionIndexStr = log["transactionIndex"] as? String, let transactionIndex = Int(transactionIndexStr.stripHexPrefix(), radix: 16) else {
            return nil
        }

        self.address = address
        self.blockHash = blockHash
        self.blockNumber = blockNumber
        self.data = data
        self.logIndex = logIndex
        self.removed = removed
        self.topics = topics.compactMap { Data(hex: $0) }
        self.transactionHash = transactionHash
        self.transactionIndex = transactionIndex
    }

}

extension EthereumLog: Equatable {

    public static func ==(lhs: EthereumLog, rhs: EthereumLog) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }

}

extension EthereumLog: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(transactionHash)
        hasher.combine(logIndex)
    }

}
