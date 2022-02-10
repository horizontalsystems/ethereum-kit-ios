public enum GasPrice {
    case legacy(gasPrice: Int)
    case eip1559(maxFeePerGas: Int, maxPriorityFeePerGas: Int)

    public var max: Int {
        switch self {
        case .legacy(let gasPrice): return gasPrice
        case .eip1559(let maxFeePerGas, _): return maxFeePerGas
        }
    }
}

extension GasPrice: CustomStringConvertible {

    public var description: String {
        switch self {
        case .legacy(let gasPrice): return "Legacy(\(gasPrice))"
        case  .eip1559(let maxFeePerGas, let maxPriorityFeePerGas): return "EIP1559(\(maxFeePerGas),\(maxPriorityFeePerGas))"
        }
    }

}
