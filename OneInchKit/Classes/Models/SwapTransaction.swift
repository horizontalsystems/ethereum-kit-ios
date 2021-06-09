import BigInt
import EthereumKit

public struct SwapTransaction {
    public let from: Address
    public let to: Address
    public let data: Data
    public let value: BigUInt
    public let gasPrice: Int
    public let gasLimit: Int

    init(from: Address, to: Address, data: Data, value: BigUInt, gasPrice: Int, gasLimit: Int) {
        self.from = from
        self.to = to
        self.data = data
        self.value = value
        self.gasPrice = gasPrice
        self.gasLimit = gasLimit
    }

}


extension SwapTransaction: CustomStringConvertible {

    public var description: String {
        "[SwapTransaction {from \(from.hex); to: \(to.hex); data: \(data.hex); value: \(value.description); gasPrice: \(gasPrice); gasLimit: \(gasLimit)]"
    }

}
