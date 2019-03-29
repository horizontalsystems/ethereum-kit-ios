import HSCryptoKit

struct ERC20 {

    enum ContractFunctions {
        case balanceOf(address: Data)
        case transfer(address: Data, amount: BInt)

        var methodSignature: Data {
            switch self {
            case .balanceOf:
                return generateSignature(method: "balanceOf(address)")
            case .transfer:
                return generateSignature(method: "transfer(address,uint256)")
            }
        }

        private func generateSignature(method: String) -> Data {
            return CryptoKit.sha3(method.data(using: .ascii)!)[0...3]
        }

        var data: Data {
            switch self {

            case .balanceOf(let address):
                return methodSignature + pad(data: address)

            case .transfer(let toAddress, let amount):
                return methodSignature + pad(data: toAddress) + pad(data: amount.serialize())
            }
        }

        private func pad(data: Data) -> Data {
            return Data(repeating: 0, count: (max(0, 32 - data.count))) + data
        }

    }

}
