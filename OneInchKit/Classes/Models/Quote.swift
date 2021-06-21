import BigInt
import Foundation

public struct Quote {
    public let fromToken: Token
    public let toToken: Token
    public let fromTokenAmount: BigUInt
    public let toTokenAmount: BigUInt
    public let route: [Any]
    public let estimateGas: Int

    public init(fromToken: Token, toToken: Token, fromTokenAmount: BigUInt, toTokenAmount: BigUInt, route: [Any], estimateGas: Int) {
        self.fromToken = fromToken
        self.toToken = toToken
        self.fromTokenAmount = fromTokenAmount
        self.toTokenAmount = toTokenAmount
        self.route = route
        self.estimateGas = estimateGas
    }

}

extension Quote: CustomStringConvertible {

    public var description: String {
        "[Quote {fromToken:\(fromToken.name) - toToken:\(toToken.name); fromAmount: \(fromTokenAmount.description) - toAmount: \(toTokenAmount.description)]"
    }

}

extension Quote {

    public var amountIn: Decimal? {
        fromTokenAmount.toDecimal(decimals: fromToken.decimals)
    }

    public var amountOut: Decimal? {
        toTokenAmount.toDecimal(decimals: toToken.decimals)
    }

}
