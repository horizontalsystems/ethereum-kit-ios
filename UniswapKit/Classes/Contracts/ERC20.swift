import OpenSslKit
import BigInt

struct ERC20 {

    enum ContractFunctions {
        case approve(spender: Data, amount: BigUInt)

        var methodSignature: Data {
            switch self {
            case .approve:
                return generateSignature(method: "approve(address,uint256)")
            }
        }

        private func generateSignature(method: String) -> Data {
            OpenSslKit.Kit.sha3(method.data(using: .ascii)!)[0...3]
        }

        var data: Data {
            switch self {
            case let .approve(spender, amount):
                return methodSignature + pad(data: spender) + pad(data: amount.serialize())
            }
        }

        private func pad(data: Data) -> Data {
            Data(repeating: 0, count: (max(0, 32 - data.count))) + data
        }

    }

}
