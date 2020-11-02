import EthereumKit
import BigInt

public struct TransactionData {
    public var to: Address
    public var value: BigUInt
    public var input: Data
}
