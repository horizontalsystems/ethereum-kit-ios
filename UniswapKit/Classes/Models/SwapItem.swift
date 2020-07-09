public enum SwapItem {
    case ethereum
    case erc20(contractAddress: String)
}

extension SwapItem: Equatable {

    public static func ==(lhs: SwapItem, rhs: SwapItem) -> Bool {
        switch (lhs, rhs) {
        case (.ethereum, .ethereum): return true
        case (.erc20(let lhsContractAddress), .erc20(let rhsContractAddress)): return lhsContractAddress == rhsContractAddress
        default: return false
        }
    }

}
