public struct Block {

//    public let hash: Data
//    public let parentHash: Data
//    public let unclesHash: Data
//    public let coinbase: Data
//    public let stateRoot: Data
//    public let transactionsRoot: Data
//    public let receiptsRoot: Data
//    public let logsBloom: Data
//    public let difficulty: BigUInt
    public let number: Int
//    public let gasLimit: Int
//    public let gasUsed: Int
    public let timestamp: Int
//    public let extraData: Data
//    public let mixHash: Data
//    public let nonce: Data
//    public let transactionHashes: [Data]

    init?(json: Any) {
        guard let log = json as? [String: Any] else {
            return nil
        }

        guard let numberStr = log["number"] as? String, let number = Int(numberStr.stripHexPrefix(), radix: 16) else {
            return nil
        }

        guard let timestampStr = log["timestamp"] as? String, let timestamp = Int(timestampStr.stripHexPrefix(), radix: 16) else {
            return nil
        }

        self.number = number
        self.timestamp = timestamp
    }

    init(number: Int, timestamp: Int) {
        self.number = number
        self.timestamp = timestamp
    }

}
