import BigInt

class RawTransaction {
    let gasPrice: Int
    let gasLimit: Int
    let to: Address
    let value: BigUInt
    let data: Data

    init(gasPrice: Int, gasLimit: Int, to: Address, value: BigUInt, data: Data) {
        self.gasPrice = gasPrice
        self.gasLimit = gasLimit
        self.to = to
        self.value = value
        self.data = data
    }

}

extension RawTransaction: CustomStringConvertible {

    public var description: String {
        "RAW TRANSACTION [gasPrice: \(gasPrice); gasLimit: \(gasLimit); to: \(to); value: \(value); data: \(data.toHexString())]"
    }

}
