import BigInt

class RawTransaction {
    let gasPrice: Int
    let gasLimit: Int
    let to: Data
    let value: BigUInt
    let data: Data

    init(gasPrice: Int, gasLimit: Int, to: Data, value: BigUInt, data: Data) {
        self.gasPrice = gasPrice
        self.gasLimit = gasLimit
        self.to = to
        self.value = value
        self.data = data
    }

}

extension RawTransaction: CustomStringConvertible {

    public var description: String {
        return "RAW TRANSACTION [gasPrice: \(gasPrice); gasLimit: \(gasLimit); to: \(to.toHexString()); value: \(value); data: \(data.toHexString())]"
    }

}
