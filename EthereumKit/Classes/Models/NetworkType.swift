public enum NetworkType {
    case ethMainNet
    case bscMainNet
    case ropsten
    case kovan

    var network: INetwork {
        switch self {
        case .ethMainNet:
            return EthMainNet()
        case .bscMainNet:
            return BscMainNet()
        case .ropsten:
            return Ropsten()
        case .kovan:
            return Kovan()
        }
    }

    public var chainId: Int {
        network.chainId
    }

    var blockTime: TimeInterval {
        network.blockTime
    }

}
