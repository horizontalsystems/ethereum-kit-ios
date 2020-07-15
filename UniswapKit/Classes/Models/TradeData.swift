import BigInt

public class TradeData {
    let trade: Trade
    let options: TradeOptions

    init(trade: Trade, options: TradeOptions) {
        self.trade = trade
        self.options = options
    }

    var tokenAmountInMax: TokenAmount {
        let amountInMax = ((Fraction(numerator: 1) + options.slippageFraction) * Fraction(numerator: trade.tokenAmountIn.rawAmount)).quotient
        return TokenAmount(token: trade.tokenAmountIn.token, rawAmount: amountInMax)
    }

    var tokenAmountOutMin: TokenAmount {
        let amountOutMin = ((Fraction(numerator: 1) + options.slippageFraction).inverted * Fraction(numerator: trade.tokenAmountOut.rawAmount)).quotient
        return TokenAmount(token: trade.tokenAmountOut.token, rawAmount: amountOutMin)
    }

}

extension TradeData {

    public var type: TradeType {
        trade.type
    }

    public var amountIn: Decimal? {
        trade.tokenAmountIn.decimalAmount
    }

    public var amountOut: Decimal? {
        trade.tokenAmountOut.decimalAmount
    }

    public var amountInMax: Decimal? {
        tokenAmountInMax.decimalAmount
    }

    public var amountOutMin: Decimal? {
        tokenAmountOutMin.decimalAmount
    }

    public var priceImpact: Decimal? {
        trade.priceImpact.toDecimal(decimals: 2)
    }

}
