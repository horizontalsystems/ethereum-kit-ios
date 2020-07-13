import RxSwift
import EthereumKit
import BigInt

public class Kit {
    private let disposeBag = DisposeBag()

    private let tradeManager: TradeManager
    private let pairSelector: PairSelector
    private let tokenFactory: TokenFactory

    init(tradeManager: TradeManager, pairSelector: PairSelector, tokenFactory: TokenFactory) {
        self.tradeManager = tradeManager
        self.pairSelector = pairSelector
        self.tokenFactory = tokenFactory
    }

}

extension Kit {

    public var etherToken: Token {
        tokenFactory.etherToken
    }

    public func token(contractAddress: Data) -> Token {
        tokenFactory.token(contractAddress: contractAddress)
    }

    public func swapDataSingle(tokenIn: Token, tokenOut: Token) -> Single<SwapData> {
        let tokenPairs = pairSelector.tokenPairs(tokenA: tokenIn, tokenB: tokenOut)

        let singles = tokenPairs.map { tokenA, tokenB in
            tradeManager.pairSingle(tokenA: tokenA, tokenB: tokenB)
        }

        return Single.zip(singles) { pairs in
            SwapData(pairs: pairs, tokenIn: tokenIn, tokenOut: tokenOut)
        }
    }

    public func bestTradeExactIn(swapData: SwapData, amountIn: BigUInt, options: TradeOptions = TradeOptions()) -> TradeData? {
        let tokenAmountIn = TokenAmount(token: swapData.tokenIn, amount: amountIn)

        do {
            let trades = try TradeManager.bestTradeExactIn(
                    pairs: swapData.pairs,
                    tokenAmountIn: tokenAmountIn,
                    tokenOut: swapData.tokenOut
            )

            guard let trade = trades.first else {
                return nil
            }

            print("PATH: \(trade.route.path)")

            return TradeData(trade: trade, options: options)
        } catch {
            print("BestTradeError: \(error)")
            return nil
        }
    }

    public func bestTradeExactOut(swapData: SwapData, amountOut: BigUInt, options: TradeOptions = TradeOptions()) -> TradeData? {
        let tokenAmountOut = TokenAmount(token: swapData.tokenOut, amount: amountOut)

        do {
            let trades = try TradeManager.bestTradeExactOut(
                    pairs: swapData.pairs,
                    tokenIn: swapData.tokenIn,
                    tokenAmountOut: tokenAmountOut
            )

            guard let trade = trades.first else {
                return nil
            }

            print("PATH: \(trade.route.path)")

            return TradeData(trade: trade, options: options)
        } catch {
            print("BestTradeError: \(error)")
            return nil
        }
    }

    public func swapSingle(tradeData: TradeData) -> Single<String> {
        tradeManager.swapSingle(tradeData: tradeData)
    }

}

extension Kit {

    public static func instance(ethereumKit: EthereumKit.Kit, networkType: NetworkType) throws -> Kit {
        let address = ethereumKit.address

        let tradeManager = try TradeManager(ethereumKit: ethereumKit, address: address)
        let tokenFactory = TokenFactory(networkType: networkType)
        let pairSelector = PairSelector(tokenFactory: tokenFactory)

        let uniswapKit = Kit(tradeManager: tradeManager, pairSelector: pairSelector, tokenFactory: tokenFactory)

        return uniswapKit
    }

}

extension Kit {

    public enum KitError: Error {
        case insufficientReserve
    }

}
