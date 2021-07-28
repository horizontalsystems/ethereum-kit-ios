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

    public var routerAddress: Address {
        tradeManager.routerAddress
    }

    public var etherToken: Token {
        tokenFactory.etherToken
    }

    public func token(contractAddress: Address, decimals: Int) -> Token {
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
        guard amountIn > 0 else {
            throw TradeError.zeroAmount
        }

        let tokenAmountIn = try TokenAmount(token: swapData.tokenIn, decimal: amountIn)

        let sortedTrades = try TradeManager.tradesExactIn(
                pairs: swapData.pairs,
                tokenAmountIn: tokenAmountIn,
                tokenOut: swapData.tokenOut
        ).sorted()

        guard let bestTrade = sortedTrades.first else {
            throw TradeError.tradeNotFound
        }

        return TradeData(trade: bestTrade, options: options)
    }

    public func bestTradeExactOut(swapData: SwapData, amountOut: Decimal, options: TradeOptions = TradeOptions()) throws -> TradeData {
        guard amountOut > 0 else {
            throw TradeError.zeroAmount
        }

        let tokenAmountOut = try TokenAmount(token: swapData.tokenOut, decimal: amountOut)

        let sortedTrades = try TradeManager.tradesExactOut(
                pairs: swapData.pairs,
                tokenIn: swapData.tokenIn,
                tokenAmountOut: tokenAmountOut
        ).sorted()

//        print("Trades: \(sortedTrades)")

        guard let bestTrade = sortedTrades.first else {
            throw TradeError.tradeNotFound
        }

        return TradeData(trade: bestTrade, options: options)
    }

    public func transactionData(tradeData: TradeData) throws -> TransactionData {
        try tradeManager.transactionData(tradeData: tradeData)
    }

}

extension Kit {

    public static func instance(evmKit: EthereumKit.Kit) -> Kit {
        let address = evmKit.address

        let tradeManager = TradeManager(evmKit: evmKit, address: address)
        let tokenFactory = TokenFactory(networkType: evmKit.networkType)
        let pairSelector = PairSelector(tokenFactory: tokenFactory)

        let uniswapKit = Kit(tradeManager: tradeManager, pairSelector: pairSelector, tokenFactory: tokenFactory)

        return uniswapKit
    }

    public static func addDecorator(to evmKit: EthereumKit.Kit) {
        evmKit.add(decorator: SwapTransactionDecorator(address: evmKit.address, contractMethodFactories: SwapContractMethodFactories.shared))
    }

    public static func addTransactionWatcher(to evmKit: EthereumKit.Kit) {
        evmKit.add(transactionWatcher: UniswapTransactionWatcher(address: evmKit.address))
    }

}

extension Kit {

    public enum FractionError: Error {
        case negativeDecimal
        case invalidSignificand(value: String)
    }

    public enum TradeError: Error {
        case zeroAmount
        case tradeNotFound
        case invalidTokensForSwap
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
