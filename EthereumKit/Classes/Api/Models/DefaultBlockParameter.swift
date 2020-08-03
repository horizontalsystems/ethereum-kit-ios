import BigInt

public enum DefaultBlockParameter {
    case blockNumber(value: Int)
    case earliest
    case latest
    case pending

    var raw: String {
        switch self {
        case .blockNumber(let value):
            return BigUInt(value).serialize().toHexString()
        case .earliest:
            return "earliest"
        case .latest:
            return "latest"
        case .pending:
            return "pending"
        }
    }

}

extension DefaultBlockParameter: CustomStringConvertible {

    public var description: String {
        raw
    }

}
