import BigInt

struct Trade {
    let type: TradeType
    let route: Route
    let tokenAmountIn: TokenAmount
    let tokenAmountOut: TokenAmount
    let executionPrice: Price
    let priceImpact: Fraction

    init(type: TradeType, route: Route, tokenAmountIn: TokenAmount, tokenAmountOut: TokenAmount) {
        self.type = type
        self.route = route
        self.tokenAmountIn = tokenAmountIn
        self.tokenAmountOut = tokenAmountOut

        executionPrice = Price(baseTokenAmount: tokenAmountIn, quoteTokenAmount: tokenAmountOut)

        priceImpact = Trade.computePriceImpact(midPrice: route.midPrice, tokenAmountIn: tokenAmountIn, tokenAmountOut: tokenAmountOut)
    }

    private static func computePriceImpact(midPrice: Price, tokenAmountIn: TokenAmount, tokenAmountOut: TokenAmount) -> Fraction {
        let exactQuote = midPrice.fraction * Fraction(numerator: tokenAmountIn.rawAmount) * Fraction(numerator: 997, denominator: 1000)
        return (exactQuote - Fraction(numerator: tokenAmountOut.rawAmount)) / exactQuote * Fraction(numerator: 100)
    }

}
