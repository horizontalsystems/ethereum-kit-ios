import ObjectMapper
import BigInt

public class RpcTransaction: ImmutableMappable {
    public let hash: Data
    public let nonce: Int
    public let from: Address
    public var to: Address?
    public let value: BigUInt
    public let gasPrice: Int
    public let gasLimit: Int
    public let input: Data
    public var blockHash: Data?
    public var blockNumber: Int?
    public var transactionIndex: Int?

    public required init(map: Map) throws {
        hash = try map.value("hash", using: HexDataTransform())
        nonce = try map.value("nonce", using: HexIntTransform())
        from = try map.value("from", using: HexAddressTransform())
        to = try? map.value("to", using: HexAddressTransform())
        value = try map.value("value", using: HexBigUIntTransform())
        gasPrice = try map.value("gasPrice", using: HexIntTransform())
        gasLimit = try map.value("gas", using: HexIntTransform())
        input = try map.value("input", using: HexDataTransform())
        blockHash = try? map.value("blockHash", using: HexDataTransform())
        blockNumber = try? map.value("blockNumber", using: HexIntTransform())
        transactionIndex = try? map.value("transactionIndex", using: HexIntTransform())
    }

    init(hash: Data, nonce: Int, from: Address, to: Address?, value: BigUInt, gasPrice: Int, gasLimit: Int, input: Data, blockHash: Data?, blockNumber: Int?, transactionIndex: Int?) {
        self.hash = hash
        self.nonce = nonce
        self.from = from
        self.to = to
        self.value = value
        self.gasPrice = gasPrice
        self.gasLimit = gasLimit
        self.input = input
        self.blockHash = blockHash
        self.blockNumber = blockNumber
        self.transactionIndex = transactionIndex
    }

}

extension RpcTransaction: CustomStringConvertible {

    public var description: String {
        "[hash: \(hash.toHexString()); nonce: \(nonce); blockHash: \(blockHash?.toHexString() ?? "nil"); blockNumber: \(blockNumber.map { "\($0)" } ?? "nil"); transactionIndex: \(transactionIndex.map { "\($0)" } ?? "nil"); from: \(from.hex); to: \(to?.hex ?? "nil"); value: \(value); gasPrice: \(gasPrice); gas: \(gasLimit); input: \(input.hex)]"
    }

}
