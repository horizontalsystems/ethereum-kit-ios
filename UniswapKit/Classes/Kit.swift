import RxSwift
import EthereumKit
import BigInt

public class Kit {
    private static let uniswapRouterAddress = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D"
    private let wethContractAddress = "0xc778417e063141139fce010982780140aa0cd5ab"

    private let disposeBag = DisposeBag()

    private let ethereumKit: EthereumKit.Kit
    private let tradeManager: TradeManager

    init(ethereumKit: EthereumKit.Kit, tradeManager: TradeManager) {
        self.ethereumKit = ethereumKit
        self.tradeManager = tradeManager
    }

    private func convert(amount: String) throws -> BigUInt {
        guard let amount = BigUInt(amount) else {
            throw KitError.invalidAmount
        }

        return amount
    }

    private func convert(address: String) throws -> Data {
        guard let address = Data(hex: address) else {
            throw KitError.invalidAddress
        }

        return address
    }

}

extension Kit {

    public func swapExactETHForTokens(amount: String, amountOutMin: String, toContractAddress: String) -> Single<String> {
        do {
            return tradeManager.swapExactETHForTokens(
                    amount: try convert(amount: amount),
                    amountOutMin: try convert(amount: amountOutMin),
                    wethContractAddress: try convert(address: wethContractAddress),
                    toContractAddress: try convert(address: toContractAddress)
            )
        } catch {
            return Single.error(error)
        }
    }

    public func swapTokensForExactETH(amount: String, amountInMax: String, fromContractAddress: String) -> Single<String> {
        do {
            return tradeManager.swapTokensForExactETH(
                    amount: try convert(amount: amount),
                    amountInMax: try convert(amount: amountInMax),
                    fromContractAddress: try convert(address: fromContractAddress),
                    wethContractAddress: try convert(address: wethContractAddress)
            )
        } catch {
            return Single.error(error)
        }
    }

    public func amountsOutSingle(amountIn: String, fromContractAddress: String, toContractAddress: String) -> Single<(String, String)> {
        do {
            return tradeManager.amountsOutSingle(
                            amountIn: try convert(amount: amountIn),
                            fromContractAddress: try convert(address: fromContractAddress),
                            toContractAddress: try convert(address: toContractAddress)
                    )
                    .map { amountIn, amountOut in
                        (amountIn.description, amountOut.description)
                    }
        } catch {
            return Single.error(error)
        }
    }

    public func amountsInSingle(amountOut: String, fromContractAddress: String, toContractAddress: String) -> Single<(String, String)> {
        do {
            return tradeManager.amountsInSingle(
                            amountOut: try convert(amount: amountOut),
                            fromContractAddress: try convert(address: fromContractAddress),
                            toContractAddress: try convert(address: toContractAddress)
                    )
                    .map { amountIn, amountOut in
                        (amountIn.description, amountOut.description)
                    }
        } catch {
            return Single.error(error)
        }
    }

}

extension Kit {

    public static func instance(ethereumKit: EthereumKit.Kit) throws -> Kit {
        let address = ethereumKit.address

        guard let routerAddress = Data(hex: uniswapRouterAddress) else {
            throw KitError.invalidAddress
        }

        let tradeManager = TradeManager(ethereumKit: ethereumKit, routerAddress: routerAddress, address: address)

        let uniswapKit = Kit(ethereumKit: ethereumKit, tradeManager: tradeManager)

        return uniswapKit
    }

}

extension Kit {

    public enum KitError: Error {
        case invalidAmount
        case invalidAddress
    }

}
