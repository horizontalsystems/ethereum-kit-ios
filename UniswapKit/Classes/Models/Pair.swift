import EthereumKit
import OpenSslKit
import BigInt

public struct Pair {
    let reserve0: TokenAmount
    let reserve1: TokenAmount

    init(reserve0: TokenAmount, reserve1: TokenAmount) {
        self.reserve0 = reserve0
        self.reserve1 = reserve1
    }

    var token0: Token {
        reserve0.token
    }

    var token1: Token {
        reserve1.token
    }

    func involves(token: Token) -> Bool {
        token0 == token || token1 == token
    }

    func other(token: Token) -> Token {
        token0 == token ? token1 : token0
    }

    private func reserve(token: Token) -> TokenAmount {
        token0 == token ? reserve0 : reserve1
    }

    func tokenAmountOut(tokenAmountIn: TokenAmount) throws -> TokenAmount {
        guard involves(token: tokenAmountIn.token) else {
            throw Kit.PairError.notInvolvedToken
        }

        guard reserve0.rawAmount != 0 && reserve1.rawAmount != 0 else {
            throw Kit.PairError.insufficientReserves
        }

        let tokenIn = tokenAmountIn.token
        let tokenOut = other(token: tokenIn)

        let reserveIn = reserve(token: tokenIn)
        let reserveOut = reserve(token: tokenOut)

        let amountInWithFee = tokenAmountIn.rawAmount * 997
        let numerator = amountInWithFee * reserveOut.rawAmount
        let denominator = reserveIn.rawAmount * 1000 + amountInWithFee
        let amountOut = numerator / denominator

        return TokenAmount(token: tokenOut, rawAmount: amountOut)
    }

    func tokenAmountIn(tokenAmountOut: TokenAmount) throws -> TokenAmount {
        guard involves(token: tokenAmountOut.token) else {
            throw Kit.PairError.notInvolvedToken
        }

        guard reserve0.rawAmount != 0 && reserve1.rawAmount != 0 else {
            throw Kit.PairError.insufficientReserves
        }

        let amountOut = tokenAmountOut.rawAmount

        let tokenOut = tokenAmountOut.token
        let tokenIn = other(token: tokenOut)

        let reserveOut = reserve(token: tokenOut)
        let reserveIn = reserve(token: tokenIn)

        guard amountOut < reserveOut.rawAmount else {
            throw Kit.PairError.insufficientReserveOut
        }

        let numerator = reserveIn.rawAmount * amountOut * 1000
        let denominator = (reserveOut.rawAmount - amountOut) * 997
        let amountIn = numerator / denominator + 1

        return TokenAmount(token: tokenIn, rawAmount: amountIn)
    }

}

extension Pair {

    static func address(token0: Token, token1: Token, factoryAddressString: String, initCodeHashString: String) -> Address {
        let data = Data(hex: "ff")! +
                Data(hex: factoryAddressString)! +
                OpenSslKit.Kit.sha3(token0.address.raw + token1.address.raw) +
                Data(hex: initCodeHashString)!

        return Address(raw: OpenSslKit.Kit.sha3(data).suffix(20))
    }

}

extension Pair: CustomStringConvertible {

    public var description: String {
        "[reserve0: \(reserve0); reserve1: \(reserve1)]"
    }

}
