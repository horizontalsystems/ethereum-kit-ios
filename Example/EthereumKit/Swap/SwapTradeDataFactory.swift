import EthereumKit
import UniswapKit
import OneInchKit

class SwapTradeDataFactory {
    private let swapTokenFactory: SwapTokenFactory

    init(swapTokenFactory: SwapTokenFactory) {
        self.swapTokenFactory = swapTokenFactory
    }

    func swapTradeData(tradeData: TradeData) -> SwapTradeData {
        let path = tradeData.path.map {
            swapTokenFactory.swapToken(uniswapToken: $0)
        }

        return SwapTradeData(amountIn: tradeData.amountIn,
                amountOut: tradeData.amountOut,
                amountInMax: tradeData.amountInMax,
                amountOutMin: tradeData.amountOutMin,
                executionPrice: tradeData.executionPrice,
                midPrice: tradeData.midPrice,
                priceImpact: tradeData.priceImpact,
                providerFee: tradeData.providerFee,
                path: path)
    }

    func swapTradeData(quote: Quote) -> SwapTradeData {
        let amountIn = Decimal(string: quote.fromTokenAmount.description).map { $0 / pow(10, quote.fromToken.decimals) }
        let amountOut = Decimal(string: quote.toTokenAmount.description).map { $0 / pow(10, quote.toToken.decimals) }

        return SwapTradeData(amountIn: amountIn,
                amountOut: amountOut,
                amountInMax: nil,
                amountOutMin: nil,
                executionPrice: nil,
                midPrice: nil,
                priceImpact: nil,
                providerFee: nil,
                path: [])
    }

}
