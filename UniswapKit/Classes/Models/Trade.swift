import BigInt

public struct Trade {
    public let type: TradeType
    let route: Route
    let tokenAmountIn: TokenAmount
    let tokenAmountOut: TokenAmount

    private func amountInMax(slippage: Double) -> BigUInt {
        tokenAmountIn.amount * (100_00 + BigUInt(slippage * 100)) / 100_00
    }

    private func amountOutMin(slippage: Double) -> BigUInt {
        tokenAmountOut.amount * (100_00 - BigUInt(slippage * 100)) / 100_00
    }

    public var amountIn: String {
        tokenAmountIn.amount.description
    }

    public var amountOut: String {
        tokenAmountOut.amount.description
    }

    public func amountInMax(slippage: Double) -> String {
        let value: BigUInt = amountInMax(slippage: slippage)
        return value.description
    }

    public func amountOutMin(slippage: Double) -> String {
        let value: BigUInt = amountOutMin(slippage: slippage)
        return value.description
    }

}
