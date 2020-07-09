public struct Trade {
    public let type: TradeType
    let route: Route
    let tokenAmountIn: TokenAmount
    let tokenAmountOut: TokenAmount

    public var amountIn: String {
        tokenAmountIn.amount.description
    }

    public var amountOut: String {
        tokenAmountOut.amount.description
    }

}
