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

    private func tradeInfo(trade: Trade) -> TradeInfo {
        TradeInfo(
                trade: trade,
                type: trade.type,
                amountIn: trade.tokenAmountIn.amount.description,
                amountOut: trade.tokenAmountOut.amount.description
        )
    }

}

extension Kit {

    public func pairsSingle(itemIn: SwapItem, itemOut: SwapItem) -> Single<[Pair]> {
        do {
            return tradeManager.pairsSingle(
                            tokenIn: try swapConverter.address(swapItem: itemIn),
                            tokenOut: try swapConverter.address(swapItem: itemOut)
                    )
        } catch {
            return Single.error(error)
        }
    }

    public func bestTradeExactIn(pairs: [Pair], itemIn: SwapItem, itemOut: SwapItem, amountIn: String) -> TradeInfo? {
        do {
            let tokenAmountIn = TokenAmount(
                    token: try swapConverter.address(swapItem: itemIn),
                    amount: try convert(amount: amountIn)
            )

            let trade = TradeManager.bestTradeExactIn(
                    pairs: pairs,
                    tokenAmountIn: tokenAmountIn,
                    tokenOut: try swapConverter.address(swapItem: itemOut)
            )

            return trade.map { tradeInfo(trade: $0) }
        } catch {
            return nil
        }
    }

    public func bestTradeExactOut(pairs: [Pair], itemIn: SwapItem, itemOut: SwapItem, amountOut: String) -> TradeInfo? {
        do {
            let tokenAmountOut = TokenAmount(
                    token: try swapConverter.address(swapItem: itemOut),
                    amount: try convert(amount: amountOut)
            )

            let trade = TradeManager.bestTradeExactOut(
                    pairs: pairs,
                    tokenIn: try swapConverter.address(swapItem: itemIn),
                    tokenAmountOut: tokenAmountOut
            )

            return trade.map { tradeInfo(trade: $0) }
        } catch {
            return nil
        }
    }

    public func swapSingle(tradeInfo: TradeInfo) -> Single<String> {
        let trade = tradeInfo.trade

        let wethIn = swapConverter.isWeth(address: trade.tokenAmountIn.token)
        let wethOut = swapConverter.isWeth(address: trade.tokenAmountOut.token)

        switch trade.type {
        case .exactIn:
            let amountIn = trade.tokenAmountIn.amount
            let amountOutMin = trade.tokenAmountOut.amount // todo: apply slippage
            let path = [trade.tokenAmountIn.token, trade.tokenAmountOut.token] // todo: compute path in Route

            switch (wethIn, wethOut) {
            case (true, false): return tradeManager.swapExactETHForTokens(amountIn: amountIn, amountOutMin: amountOutMin, path: path)
            case (false, true): return tradeManager.swapExactTokensForETH(amountIn: amountIn, amountOutMin: amountOutMin, path: path)
            case (false, false): return tradeManager.swapExactTokensForTokens(amountIn: amountIn, amountOutMin: amountOutMin, path: path)
            default: fatalError()
            }

        case .exactOut:
            let amountOut = trade.tokenAmountOut.amount
            let amountInMax = trade.tokenAmountIn.amount // todo: apply slippage
            let path = [trade.tokenAmountIn.token, trade.tokenAmountOut.token] // todo: compute path in Route

            switch (wethIn, wethOut) {
            case (true, false): return tradeManager.swapETHForExactTokens(amountOut: amountOut, amountInMax: amountInMax, path: path)
            case (false, true): return tradeManager.swapTokensForExactETH(amountOut: amountOut, amountInMax: amountInMax, path: path)
            case (false, false): return tradeManager.swapTokensForExactTokens(amountOut: amountOut, amountInMax: amountInMax, path: path)
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
    }

}
