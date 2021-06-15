import EthereumKit

public enum SwapToken {
    case eth(wethAddress: Address)
    case erc20(address: Address, decimals: Int)

    public var address: Address {
        switch self {
        case .eth(let wethAddress): return wethAddress
        case .erc20(let address, _): return address
        }
    }

    public var decimals: Int {
        switch self {
        case .eth: return 18
        case .erc20(_, let decimals): return decimals
        }
    }

    public func sortsBefore(token: SwapToken) -> Bool {
        address.raw.toHexString().lowercased() < token.address.raw.toHexString().lowercased()
    }

    public var isEther: Bool {
        switch self {
        case .eth: return true
        default: return false
        }
    }

}

extension SwapToken: Equatable {

    public static func ==(lhs: SwapToken, rhs: SwapToken) -> Bool {
        switch (lhs, rhs) {
        case (.eth(let lhsWethAddress), .eth(let rhsWethAddress)): return lhsWethAddress == rhsWethAddress
        case (.erc20(let lhsAddress, let lhsDecimals), .erc20(let rhsAddress, let rhsDecimals)): return lhsAddress == rhsAddress && lhsDecimals == rhsDecimals
        default: return false
        }
    }

}

extension SwapToken: CustomStringConvertible {

    public var description: String {
        switch self {
        case .eth: return "[ETH]"
        case .erc20(let address, _): return "[ERC20: \(address)]"
        }
    }

}
