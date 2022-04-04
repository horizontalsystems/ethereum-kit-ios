import BigInt

public struct ProviderTransaction {
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
}
