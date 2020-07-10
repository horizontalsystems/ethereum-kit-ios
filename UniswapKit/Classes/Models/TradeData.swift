import BigInt

public class TradeData {
    let trade: Trade
    let options: TradeOptions

    init(trade: Trade, options: TradeOptions) {
        self.trade = trade
        self.options = options
    }

    var tokenAmountInMax: TokenAmount {
        TokenAmount(
                token: trade.tokenAmountIn.token,
                amount: trade.tokenAmountIn.amount * (100_00 + BigUInt(options.allowedSlippage * 100)) / 100_00
        )
    }

    var tokenAmountOutMin: TokenAmount {
        TokenAmount(
                token: trade.tokenAmountOut.token,
                amount: trade.tokenAmountOut.amount * (100_00 - BigUInt(options.allowedSlippage * 100)) / 100_00
        )
    }

    public var type: TradeType {
        trade.type
    }

    public var amountIn: String {
        trade.tokenAmountIn.amount.description
    }

    public var amountOut: String {
        trade.tokenAmountOut.amount.description
    }

    public var amountInMax: String {
        tokenAmountInMax.amount.description
    }

    public var amountOutMin: String {
        tokenAmountOutMin.amount.description
    }

}
