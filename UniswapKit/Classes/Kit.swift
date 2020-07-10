import RxSwift
import EthereumKit
import BigInt

public class Kit {
    private let disposeBag = DisposeBag()

    private let swapConverter: SwapConverter
    private let tradeManager: TradeManager

    init(swapConverter: SwapConverter, tradeManager: TradeManager) {
        self.swapConverter = swapConverter
        self.tradeManager = tradeManager
    }

    private func convert(amount: String) throws -> BigUInt {
        guard let amount = BigUInt(amount) else {
            throw KitError.invalidAmount
        }

        return amount
    }

}

extension Kit {

    public func swapDataSingle(itemIn: SwapItem, itemOut: SwapItem) -> Single<SwapData> {
        do {
            let tokenIn = try swapConverter.token(swapItem: itemIn)
            let tokenOut = try swapConverter.token(swapItem: itemOut)

            return tradeManager.pairsSingle(tokenIn: tokenIn, tokenOut: tokenOut)
                    .map { pairs in
                        SwapData(pairs: pairs, tokenIn: tokenIn, tokenOut: tokenOut)
                    }
        } catch {
            return Single.error(error)
        }
    }

    public func bestTradeExactIn(swapData: SwapData, amountIn: String, options: TradeOptions) -> TradeData? {
        do {
            let tokenAmountIn = TokenAmount(
                    token: swapData.tokenIn,
                    amount: try convert(amount: amountIn)
            )

            guard let trade = TradeManager.bestTradeExactIn(
                    pairs: swapData.pairs,
                    tokenAmountIn: tokenAmountIn,
                    tokenOut: swapData.tokenOut
            ) else {
                return nil
            }

            return TradeData(trade: trade, options: options)
        } catch {
            return nil
        }
    }

    public func bestTradeExactOut(swapData: SwapData, amountOut: String, options: TradeOptions) -> TradeData? {
        do {
            let tokenAmountOut = TokenAmount(
                    token: swapData.tokenOut,
                    amount: try convert(amount: amountOut)
            )

            guard let trade = TradeManager.bestTradeExactOut(
                    pairs: swapData.pairs,
                    tokenIn: swapData.tokenIn,
                    tokenAmountOut: tokenAmountOut
            ) else {
                return nil
            }

            return TradeData(trade: trade, options: options)
        } catch {
            return nil
        }
    }

    public func swapSingle(tradeData: TradeData) -> Single<String> {
        let trade = tradeData.trade

        let tokenIn = trade.tokenAmountIn.token
        let tokenOut = trade.tokenAmountOut.token

        let amountIn = trade.tokenAmountIn.amount
        let amountOut = trade.tokenAmountOut.amount

        let path = [tokenIn, tokenOut].map { $0.address } // todo: compute path in Route

        switch trade.type {
        case .exactIn:
            let amountOutMin = amountOut // todo: apply slippage

            switch (tokenIn, tokenOut) {
            case (.eth, .erc20): return tradeManager.swapExactETHForTokens(amountIn: amountIn, amountOutMin: amountOutMin, path: path)
            case (.erc20, .eth): return tradeManager.swapExactTokensForETH(amountIn: amountIn, amountOutMin: amountOutMin, path: path)
            case (.erc20, .erc20): return tradeManager.swapExactTokensForTokens(amountIn: amountIn, amountOutMin: amountOutMin, path: path)
            default: fatalError()
            }

        case .exactOut:
            let amountInMax = amountIn // todo: apply slippage

            switch (tokenIn, tokenOut) {
            case (.eth, .erc20): return tradeManager.swapETHForExactTokens(amountOut: amountOut, amountInMax: amountInMax, path: path)
            case (.erc20, .eth): return tradeManager.swapTokensForExactETH(amountOut: amountOut, amountInMax: amountInMax, path: path)
            case (.erc20, .erc20): return tradeManager.swapTokensForExactTokens(amountOut: amountOut, amountInMax: amountInMax, path: path)
            default: fatalError()
            }
        }
    }

}

extension Kit {

    public static func instance(ethereumKit: EthereumKit.Kit, networkType: NetworkType) throws -> Kit {
        let address = ethereumKit.address

        let swapConverter = try SwapConverter(networkType: networkType)
        let tradeManager = try TradeManager(ethereumKit: ethereumKit, address: address)
        let uniswapKit = Kit(swapConverter: swapConverter, tradeManager: tradeManager)

        return uniswapKit
    }

}

extension Kit {

    public enum KitError: Error {
        case invalidAmount
        case invalidAddress
        case invalidPathItems

        case insufficientReserve
    }

}
