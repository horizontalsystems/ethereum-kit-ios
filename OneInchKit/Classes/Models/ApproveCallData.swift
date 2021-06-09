import EthereumKit
import BigInt

public struct ApproveCallData {
    public let data: Data
    public let gasPrice: Int
    public let to: Address
    public let value: BigUInt

    init(data: Data, gasPrice: Int, to: Address, value: BigUInt) {
        self.data = data
        self.gasPrice = gasPrice
        self.to = to
        self.value = value
    }

}

extension ApproveCallData: CustomStringConvertible {

    public var description: String {
        "[ApproveCallData: \nto: \(to.hex); \nvalue: \(value.description); \ndata: \(data.hex)]"
    }

}
