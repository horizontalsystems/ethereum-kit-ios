import BigInt

public class TradeData {
    let trade: Trade
    public let options: TradeOptions

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

    public var executionPrice: Decimal? {
        trade.executionPrice.decimalValue
    }

    public var midPrice: Decimal? {
        trade.route.midPrice.decimalValue
    }

    public var priceImpact: Decimal? {
        trade.priceImpact.toDecimal(decimals: 2)
    }

    public var providerFee: Decimal? {
        guard let amountIn = type == .exactIn ? trade.tokenAmountIn.decimalAmount : tokenAmountInMax.decimalAmount else {
            return nil
        }

        return trade.liquidityProviderFee.toDecimal(decimals: trade.tokenAmountIn.token.decimals).map { $0 * amountIn }
    }

    public var path: [Token] {
        trade.route.path
    }

}
