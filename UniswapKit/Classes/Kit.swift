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

    public func token(contractAddress: Data, decimals: Int) -> Token {
        tokenFactory.token(contractAddress: contractAddress, decimals: decimals)
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

    public func bestTradeExactIn(swapData: SwapData, amountIn: Decimal, options: TradeOptions = TradeOptions()) throws -> TradeData {
        let tokenAmountIn = try TokenAmount(token: swapData.tokenIn, decimal: amountIn)

        let trades = try TradeManager.bestTradeExactIn(
                pairs: swapData.pairs,
                tokenAmountIn: tokenAmountIn,
                tokenOut: swapData.tokenOut
        )

        guard let trade = trades.first else {
            throw BestTradeError.tradeNotFound
        }

        print("Trades Found: \(trades.count)")
        print("PATH: \(trade.route.path)")

        return TradeData(trade: trade, options: options)
    }

    public func bestTradeExactOut(swapData: SwapData, amountOut: Decimal, options: TradeOptions = TradeOptions()) throws -> TradeData {
        let tokenAmountOut = try TokenAmount(token: swapData.tokenOut, decimal: amountOut)

        let trades = try TradeManager.bestTradeExactOut(
                pairs: swapData.pairs,
                tokenIn: swapData.tokenIn,
                tokenAmountOut: tokenAmountOut
        )

        guard let trade = trades.first else {
            throw BestTradeError.tradeNotFound
        }

        print("Trades Found: \(trades.count)")
        print("PATH: \(trade.route.path)")

        return TradeData(trade: trade, options: options)
    }

    public func estimateGasSingle(tradeData: TradeData, gasPrice: Int) -> Single<GasData> {
        tradeManager.estimateGasSingle(tradeData: tradeData, gasPrice: gasPrice)
    }

    public func swapSingle(tradeData: TradeData, gasData: GasData, gasPrice: Int) -> Single<String> {
        tradeManager.swapSingle(tradeData: tradeData, gasData: gasData, gasPrice: gasPrice)
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

    public enum FractionError: Error {
        case negativeDecimal
        case invalidSignificand(value: String)
    }

    public enum BestTradeError: Error {
        case tradeNotFound
    }

    public enum PairError: Error {
        case notInvolvedToken
        case insufficientReserves
        case insufficientReserveOut
    }

    public enum RouteError: Error {
        case emptyPairs
        case invalidPair(index: Int)
    }

}
