import BigInt

public class RawTransaction {
    let gasPrice: GasPrice
    let gasLimit: Int
    let to: Address
    let value: BigUInt
    let data: Data
    let nonce: Int

    init(gasPrice: GasPrice, gasLimit: Int, to: Address, value: BigUInt, data: Data, nonce: Int) {
        self.gasPrice = gasPrice
        self.gasLimit = gasLimit
        self.to = to
        self.value = value
        self.data = data
        self.nonce = nonce
    }

}

extension RawTransaction: CustomStringConvertible {

    public var description: String {
        "RAW TRANSACTION [gasPrice: \(gasPrice); gasLimit: \(gasLimit); to: \(to); value: \(value); data: \(data.toHexString())]"
    }

}
