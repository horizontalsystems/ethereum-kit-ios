import BigInt

public struct ProviderTokenTransaction {
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
}
