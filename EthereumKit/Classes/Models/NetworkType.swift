public enum NetworkType {
    case mainNet
    case ropsten
    case kovan

    var network: INetwork {
        switch self {
        case .mainNet:
            return MainNet()
        case .ropsten:
            return Ropsten()
        case .kovan:
            return Kovan()
        }
    }
}
