import BigInt

class EtherscanTransaction {
    public let hash: Data
    public let nonce: Int
    public let input: Data
    public let from: Address
    public let to: Address
    public let value: BigUInt
    public let gasLimit: Int
    public let gasPrice: Int
    public let timestamp: Int

    public var blockHash: Data?
    public var blockNumber: Int?
    public var gasUsed: Int?
    public var cumulativeGasUsed: Int?
    public var isError: Int?
    public var transactionIndex: Int?
    public var txReceiptStatus: Int?

    public init(hash: Data, nonce: Int, input: Data = Data(), from: Address, to: Address, value: BigUInt, gasLimit: Int, gasPrice: Int, timestamp: Int = Int(Date().timeIntervalSince1970)) {
        self.hash = hash
        self.nonce = nonce
        self.input = input
        self.from = from
        self.to = to
        self.value = value
        self.gasLimit = gasLimit
        self.gasPrice = gasPrice
        self.timestamp = timestamp
    }

}
