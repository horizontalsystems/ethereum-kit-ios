import OpenSslKit
import BigInt

public struct Pair {
    private let tokenAmount0: TokenAmount
    private let tokenAmount1: TokenAmount

    init(tokenAmount0: TokenAmount, tokenAmount1: TokenAmount) {
        self.tokenAmount0 = tokenAmount0
        self.tokenAmount1 = tokenAmount1
    }

    var token0: Token {
        tokenAmount0.token
    }

    var token1: Token {
        tokenAmount1.token
    }

    var reserve0: BigUInt {
        tokenAmount0.amount
    }

    var reserve1: BigUInt {
        tokenAmount1.amount
    }

    func involves(token: Token) -> Bool {
        token0 == token || token1 == token
    }

    func other(token: Token) -> Token {
        token0 == token ? token1 : token0
    }

    private func reserve(token: Token) -> BigUInt {
        token0 == token ? reserve0 : reserve1
    }

    func tokenAmountOut(tokenAmountIn: TokenAmount) -> TokenAmount {
        // todo: guards

        let tokenIn = tokenAmountIn.token
        let tokenOut = other(token: tokenIn)

        let reserveIn = reserve(token: tokenIn)
        let reserveOut = reserve(token: tokenOut)

        let amountInWithFee = tokenAmountIn.amount * 997
        let numerator = amountInWithFee * reserveOut
        let denominator = reserveIn * 1000 + amountInWithFee
        let amountOut = numerator / denominator

        return TokenAmount(token: tokenOut, amount: amountOut)
    }

    func tokenAmountIn(tokenAmountOut: TokenAmount) throws -> TokenAmount {
        // todo: guards

        let amountOut = tokenAmountOut.amount

        let tokenOut = tokenAmountOut.token
        let tokenIn = other(token: tokenOut)

        let reserveOut = reserve(token: tokenOut)
        let reserveIn = reserve(token: tokenIn)

        guard amountOut < reserveOut else {
            throw Kit.KitError.insufficientReserve
        }

        let numerator = reserveIn * amountOut * 1000
        let denominator = (reserveOut - amountOut) * 997
        let amountIn = numerator / denominator + 1

        return TokenAmount(token: tokenIn, amount: amountIn)
    }

    static func address(token0: Token, token1: Token) -> Data {
        let data = Data(hex: "ff")! +
                Data(hex: "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f")! +
                OpenSslKit.Kit.sha3(token0.address + token1.address) +
                Data(hex: "0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f")!

        return OpenSslKit.Kit.sha3(data).suffix(20)
    }

}

extension Pair: CustomStringConvertible {

    public var description: String {
        "[token0: \(token0); reserve0: \(reserve0.description); token1: \(token1); reserve1: \(reserve1.description)]"
    }

}
