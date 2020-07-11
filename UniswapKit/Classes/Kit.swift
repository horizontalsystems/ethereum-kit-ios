import RxSwift
import EthereumKit
import BigInt

public class Kit {
    private let disposeBag = DisposeBag()

    private let wethAddress: Data
    private let tradeManager: TradeManager

    init(wethAddress: Data, tradeManager: TradeManager) {
        self.wethAddress = wethAddress
        self.tradeManager = tradeManager
    }

}

extension Kit {

    public var etherToken: Token {
        .eth(wethAddress: wethAddress)
    }

    public func token(contractAddress: Data) -> Token {
        .erc20(address: contractAddress)
    }

    public func swapDataSingle(tokenIn: Token, tokenOut: Token) -> Single<SwapData> {
        tradeManager.pairsSingle(tokenIn: tokenIn, tokenOut: tokenOut)
                .map { pairs in
                    SwapData(pairs: pairs, tokenIn: tokenIn, tokenOut: tokenOut)
                }
    }

    public func bestTradeExactIn(swapData: SwapData, amountIn: BigUInt, options: TradeOptions = TradeOptions()) -> TradeData? {
        let tokenAmountIn = TokenAmount(token: swapData.tokenIn, amount: amountIn)

        guard let trade = TradeManager.bestTradeExactIn(
                pairs: swapData.pairs,
                tokenAmountIn: tokenAmountIn,
                tokenOut: swapData.tokenOut
        ) else {
            return nil
        }

        return TradeData(trade: trade, options: options)
    }

    public func bestTradeExactOut(swapData: SwapData, amountOut: BigUInt, options: TradeOptions = TradeOptions()) -> TradeData? {
        let tokenAmountOut = TokenAmount(token: swapData.tokenOut, amount: amountOut)

        guard let trade = TradeManager.bestTradeExactOut(
                pairs: swapData.pairs,
                tokenIn: swapData.tokenIn,
                tokenAmountOut: tokenAmountOut
        ) else {
            return nil
        }

        return TradeData(trade: trade, options: options)
    }

    public func swapSingle(tradeData: TradeData) -> Single<String> {
        tradeManager.swapSingle(tradeData: tradeData)
    }

}

extension Kit {

    public static func instance(ethereumKit: EthereumKit.Kit, networkType: NetworkType) throws -> Kit {
        let address = ethereumKit.address

        let tradeManager = try TradeManager(ethereumKit: ethereumKit, address: address)

        let uniswapKit = Kit(
                wethAddress: wethAddress(networkType: networkType),
                tradeManager: tradeManager
        )

        return uniswapKit
    }

    private static func wethAddress(networkType: NetworkType) -> Data {
        let wethAddressHex: String

        switch networkType {
        case .mainNet: wethAddressHex = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
        case .ropsten: wethAddressHex = "0xc778417E063141139Fce010982780140Aa0cD5Ab"
        case .kovan: wethAddressHex = "0xd0A1E359811322d97991E03f863a0C30C2cF029C"
        }

        return Data(hex: wethAddressHex)!
    }

}

extension Kit {

    public enum KitError: Error {
        case insufficientReserve
    }

}
