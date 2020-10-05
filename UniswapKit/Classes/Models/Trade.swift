import BigInt

struct Trade {
    let type: TradeType
    let route: Route
    let tokenAmountIn: TokenAmount
    let tokenAmountOut: TokenAmount
    let executionPrice: Price
    let priceImpact: Fraction
    let liquidityProviderFee: Fraction

    init(type: TradeType, route: Route, tokenAmountIn: TokenAmount, tokenAmountOut: TokenAmount) {
        self.type = type
        self.route = route
        self.tokenAmountIn = tokenAmountIn
        self.tokenAmountOut = tokenAmountOut

        executionPrice = Price(baseTokenAmount: tokenAmountIn, quoteTokenAmount: tokenAmountOut)

        priceImpact = Trade.computePriceImpact(midPrice: route.midPrice, tokenAmountIn: tokenAmountIn, tokenAmountOut: tokenAmountOut)
        liquidityProviderFee = Trade.computeLiquidityProviderFee(pairCount: route.pairs.count)
    }

    private static func computePriceImpact(midPrice: Price, tokenAmountIn: TokenAmount, tokenAmountOut: TokenAmount) -> Fraction {
        let exactQuote = midPrice.fraction * Fraction(numerator: tokenAmountIn.rawAmount) * Fraction(numerator: 997, denominator: 1000)
        return (exactQuote - Fraction(numerator: tokenAmountOut.rawAmount)) / exactQuote * Fraction(numerator: 100)
    }

    private static func computeLiquidityProviderFee(pairCount: Int) -> Fraction {
        Fraction(numerator: 1) - Fraction(numerator: BigUInt(997).power(pairCount), denominator: BigUInt(1000).power(pairCount))
    }

}

extension Trade: Comparable {

    public static func <(lhs: Trade, rhs: Trade) -> Bool {
        if lhs.tokenAmountOut != rhs.tokenAmountOut {
            return lhs.tokenAmountOut > rhs.tokenAmountOut
        }

        if lhs.tokenAmountIn != rhs.tokenAmountIn {
            return lhs.tokenAmountIn < rhs.tokenAmountIn
        }

        if lhs.priceImpact != rhs.priceImpact {
            return lhs.priceImpact < rhs.priceImpact
        }

        return lhs.route.path.count < rhs.route.path.count
    }

    public static func ==(lhs: Trade, rhs: Trade) -> Bool {
        lhs.tokenAmountOut == rhs.tokenAmountOut &&
                lhs.tokenAmountIn == rhs.tokenAmountIn &&
                lhs.priceImpact == rhs.priceImpact &&
                lhs.route.path.count == rhs.route.path.count
    }

}

extension Trade: CustomStringConvertible {

    public var description: String {
        "\n[type: \(type);\npath: \(route.path);\ntokenAmountIn: \(tokenAmountIn);\ntokenAmountOut: \(tokenAmountOut);\nexecutionPrice: \(executionPrice);\npriceImpact: \(priceImpact.toDecimal(decimals: 2)?.description ?? "nil")]"
    }

}
