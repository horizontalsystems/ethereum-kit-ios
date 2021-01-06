import OpenSslKit
import BigInt

public struct ContractEvent {
    private let name: String
    private let arguments: [Argument]

    public init(name: String, arguments: [Argument] = []) {
        self.name = name
        self.arguments = arguments
    }

    public var signature: Data {
        let argumentTypes = arguments.map { $0.type }.joined(separator: ",")
        let structure = "\(name)(\(argumentTypes))"
        return OpenSslKit.Kit.sha3(structure.data(using: .ascii)!)
    }

}

extension ContractEvent {

    public enum Argument {
        case uint256
        case address

        var type: String {
            switch self {
            case .uint256: return "uint256"
            case .address: return "address"
            }
        }
    }

}
