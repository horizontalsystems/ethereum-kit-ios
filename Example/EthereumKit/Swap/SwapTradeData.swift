import BigInt

public class SwapTradeData {
    public let amountIn: Decimal?
    public let amountOut: Decimal?
    public let amountInMax: Decimal?
    public let amountOutMin: Decimal?
    public let executionPrice: Decimal?
    public let midPrice: Decimal?
    public let priceImpact: Decimal?
    public let providerFee: Decimal?
    public let path: [SwapToken]

    public init(amountIn: Decimal?, amountOut: Decimal?, amountInMax: Decimal?, amountOutMin: Decimal?, executionPrice: Decimal?, midPrice: Decimal?, priceImpact: Decimal?, providerFee: Decimal?, path: [SwapToken]) {
        self.amountIn = amountIn
        self.amountOut = amountOut
        self.amountInMax = amountInMax
        self.amountOutMin = amountOutMin
        self.executionPrice = executionPrice
        self.midPrice = midPrice
        self.priceImpact = priceImpact
        self.providerFee = providerFee
        self.path = path
    }

}
