import OpenSslKit
import BigInt

struct Uniswap {

    enum ContractFunctions {
        case WETH
        case factory
        case getAmountsOut(amountIn: BigUInt, path: [Data])
        case getAmountsIn(amountOut: BigUInt, path: [Data])
        case swapExactETHForTokens(amountOutMin: BigUInt, path: [Data], to: Data, deadline: BigUInt)
        case swapTokensForExactETH(amountOut: BigUInt, amountInMax: BigUInt, path: [Data], to: Data, deadline: BigUInt)
        case swapExactTokensForETH(amountIn: BigUInt, amountOutMin: BigUInt, path: [Data], to: Data, deadline: BigUInt)

        var methodSignature: Data {
            switch self {
            case .WETH:
                return generateSignature(method: "WETH()")
            case .factory:
                return generateSignature(method: "factory()")
            case .getAmountsOut:
                return generateSignature(method: "getAmountsOut(uint256,address[])")
            case .getAmountsIn:
                return generateSignature(method: "getAmountsIn(uint256,address[])")
            case .swapExactETHForTokens:
                return generateSignature(method: "swapExactETHForTokens(uint256,address[],address,uint256)")
            case .swapTokensForExactETH:
                return generateSignature(method: "swapTokensForExactETH(uint256,uint256,address[],address,uint256)")
            case .swapExactTokensForETH:
                return generateSignature(method: "swapExactTokensForETH(uint256,uint256,address[],address,uint256)")
            }
        }

        private func generateSignature(method: String) -> Data {
            OpenSslKit.Kit.sha3(method.data(using: .ascii)!)[0...3]
        }

        var data: Data {
            switch self {

            case .WETH:
                return methodSignature

            case .factory:
                return methodSignature

            case let .getAmountsOut(amountIn, path):
                return methodSignature +
                        pad(data: amountIn.serialize()) +
                        pad(data: BigUInt(2 * 32).serialize()) +
                        encode(path: path)

            case let .getAmountsIn(amountOut, path):
                return methodSignature +
                        pad(data: amountOut.serialize()) +
                        pad(data: BigUInt(2 * 32).serialize()) +
                        encode(path: path)

            case let .swapExactETHForTokens(amountOutMin, path, to, deadline):
                return methodSignature +
                        pad(data: amountOutMin.serialize()) +
                        pad(data: BigUInt(4 * 32).serialize()) +
                        pad(data: to) +
                        pad(data: deadline.serialize()) +
                        encode(path: path)

            case let .swapTokensForExactETH(amountOut, amountInMax, path, to, deadline):
                return methodSignature +
                        pad(data: amountOut.serialize()) +
                        pad(data: amountInMax.serialize()) +
                        pad(data: BigUInt(5 * 32).serialize()) +
                        pad(data: to) +
                        pad(data: deadline.serialize()) +
                        encode(path: path)

            case let .swapExactTokensForETH(amountIn, amountOutMin, path, to, deadline):
                return methodSignature +
                        pad(data: amountIn.serialize()) +
                        pad(data: amountOutMin.serialize()) +
                        pad(data: BigUInt(5 * 32).serialize()) +
                        pad(data: to) +
                        pad(data: deadline.serialize()) +
                        encode(path: path)

            }
        }

        private func encode(path: [Data]) -> Data {
            var data = pad(data: BigUInt(path.count).serialize())

            for address in path {
                data += pad(data: address)
            }

            return data
        }

        private func pad(data: Data) -> Data {
            Data(repeating: 0, count: (max(0, 32 - data.count))) + data
        }

    }

}

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
