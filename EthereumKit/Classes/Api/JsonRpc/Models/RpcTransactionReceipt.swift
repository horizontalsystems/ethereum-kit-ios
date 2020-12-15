import ObjectMapper
import BigInt

public class RpcTransactionReceipt: ImmutableMappable {
    public let transactionHash: Data
    public let transactionIndex: Int
    public let blockHash: Data
    public let blockNumber: Int
    public let from: Address
    public var to: Address?
    public let cumulativeGasUsed: Int
    public let gasUsed: Int
    public var contractAddress: Data?
    public let logs: [TransactionLog]
    public let logsBloom: Data

    public var root: Data?
    public var status: Int?

    public required init(map: Map) throws {
        transactionHash = try map.value("transactionHash", using: HexDataTransform())
        transactionIndex = try map.value("transactionIndex", using: HexIntTransform())
        blockHash = try map.value("blockHash", using: HexDataTransform())
        blockNumber = try map.value("blockNumber", using: HexIntTransform())
        from = try map.value("from", using: HexAddressTransform())
        to = try? map.value("to", using: HexAddressTransform())
        cumulativeGasUsed = try map.value("cumulativeGasUsed", using: HexIntTransform())
        gasUsed = try map.value("gasUsed", using: HexIntTransform())
        contractAddress = try? map.value("contractAddress", using: HexDataTransform())
        logs = try map.value("logs")
        logsBloom = try map.value("logsBloom", using: HexDataTransform())

        root = try? map.value("root", using: HexDataTransform())
        status = try? map.value("status", using: HexIntTransform())
    }

    public init(record: TransactionReceipt, logs: [TransactionLog]) {
        transactionHash = record.transactionHash
        transactionIndex = record.transactionIndex
        blockHash = record.blockHash
        blockNumber = record.blockNumber
        from = record.from
        to = record.to
        cumulativeGasUsed = record.cumulativeGasUsed
        gasUsed = record.gasUsed
        contractAddress = record.contractAddress
        self.logs = logs
        logsBloom = record.logsBloom
        root = record.root
        status = record.status
    }

}

extension RpcTransactionReceipt: CustomStringConvertible {

    public var description: String {
        "[transactionHash: \(transactionHash.toHexString()); transactionIndex: \(transactionIndex); blockHash: \(blockHash); blockNumber: \(blockNumber); status: \(status.map { "\($0)" } ?? "nil")]"
    }

}
