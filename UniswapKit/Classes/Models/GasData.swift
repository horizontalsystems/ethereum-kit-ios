public struct GasData {
    public let swapGas: Int
    public let approveGas: Int

    public init(swapGas: Int, approveGas: Int = 0) {
        self.swapGas = swapGas
        self.approveGas = approveGas
    }

    public var totalGas: Int {
        swapGas + approveGas
    }

}

extension GasData: CustomStringConvertible {

    public var description: String {
        "[swapGas: \(swapGas); approveGas: \(approveGas); total: \(totalGas)]"
    }

}
