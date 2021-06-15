public enum NetworkType {
    case ethMainNet
    case bscMainNet
    case ropsten
    case rinkeby
    case kovan
    case goerli

    public var chainId: Int {
        switch self {
        case .ethMainNet: return 1
        case .bscMainNet: return 56
        case .ropsten: return 3
        case .rinkeby: return 4
        case .kovan: return 42
        case .goerli: return 5
        }
    }

    var blockTime: TimeInterval {
        switch self {
        case .ethMainNet, .ropsten, .rinkeby, .goerli: return 15
        case .bscMainNet: return 5
        case .kovan: return 4
        }
    }

    public var isMainNet: Bool {
        switch self {
        case .ethMainNet, .bscMainNet: return true
        case .ropsten, .rinkeby, .kovan, .goerli: return false
        }
    }

}
