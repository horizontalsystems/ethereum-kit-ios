enum Token {
    case eth(wethAddress: Data)
    case erc20(address: Data)

    var address: Data {
        switch self {
        case .eth(let wethAddress): return wethAddress
        case .erc20(let address): return address
        }
    }

    func sortsBefore(token: Token) -> Bool {
        address.toHexString().lowercased() < token.address.toHexString().lowercased()
    }

}

extension Token: Equatable {

    public static func ==(lhs: Token, rhs: Token) -> Bool {
        switch (lhs, rhs) {
        case (.eth(let lhsWethAddress), .eth(let rhsWethAddress)): return lhsWethAddress == rhsWethAddress
        case (.erc20(let lhsAddress), .erc20(let rhsAddress)): return lhsAddress == rhsAddress
        default: return false
        }
    }

}

extension Token: CustomStringConvertible {

    public var description: String {
        switch self {
        case .eth: return "[ETH]"
        case .erc20(let address): return "[ERC20: \(address.toHexString())]"
        }
    }

}
