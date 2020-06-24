import RxSwift
import EthereumKit
import BigInt

public class Kit {
    private static let uniswapRouterAddress = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D"
    private static let wethContractAddress = "0xc778417e063141139fce010982780140aa0cd5ab"

    private let disposeBag = DisposeBag()

    private let ethereumKit: EthereumKit.Kit
    private let tradeManager: TradeManager
    private let wethAddress: Data

    init(ethereumKit: EthereumKit.Kit, tradeManager: TradeManager, wethAddress: Data) {
        self.ethereumKit = ethereumKit
        self.tradeManager = tradeManager
        self.wethAddress = wethAddress
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

    private func address(item: SwapItem) throws -> Data {
        switch item {
        case .ethereum: return wethAddress
        case .erc20(let contractAddress): return try convert(address: contractAddress)
        }
    }

    private func generatePath(fromItem: SwapItem, toItem: SwapItem) throws -> [Data] {
        let fromAddress = try address(item: fromItem)
        let toAddress = try address(item: toItem)

        switch (fromItem, toItem) {
        case (.erc20, .erc20): return [fromAddress, wethAddress, toAddress]
        default: return [fromAddress, toAddress]
        }
    }

    private func pathItems(path: [Data], amounts: [BigUInt]) -> [PathItem] {
        amounts.enumerated().map { index, amount in
            let address = path[index]

            return PathItem(
                    swapItem: address == wethAddress ? .ethereum : .erc20(contractAddress: address.toHexString()),
                    amount: amount.description
            )
        }
    }

}

extension Kit {

    public func amountsOutSingle(amountIn: String, fromItem: SwapItem, toItem: SwapItem) -> Single<[PathItem]> {
        do {
            let amountIn = try convert(amount: amountIn)
            let path = try generatePath(fromItem: fromItem, toItem: toItem)

            return tradeManager.amountsOutSingle(amountIn: amountIn, path: path)
                    .map { [weak self] amounts in
                        self?.pathItems(path: path, amounts: amounts) ?? []
                    }
        } catch {
            return Single.error(error)
        }
    }

    public func amountsInSingle(amountOut: String, fromItem: SwapItem, toItem: SwapItem) -> Single<[PathItem]> {
        do {
            let amountOut = try convert(amount: amountOut)
            let path = try generatePath(fromItem: fromItem, toItem: toItem)

            return tradeManager.amountsInSingle(amountOut: amountOut, path: path)
                    .map { [weak self] amounts in
                        self?.pathItems(path: path, amounts: amounts) ?? []
                    }
        } catch {
            return Single.error(error)
        }
    }

    public func swapExactItemForItem(pathItems: [PathItem]) -> Single<String> {
        do {
            let path = try pathItems.map { try address(item: $0.swapItem) }

            guard let fromPathItem = pathItems.first else {
                throw KitError.invalidPathItems
            }

            guard let toPathItem = pathItems.last else {
                throw KitError.invalidPathItems
            }

            let amountIn = try convert(amount: fromPathItem.amount)
            let amountOutMin = try convert(amount: toPathItem.amount)

            switch (fromPathItem.swapItem, toPathItem.swapItem) {
            case (.ethereum, .erc20): return tradeManager.swapExactETHForTokens(amountIn: amountIn, amountOutMin: amountOutMin, path: path)
            case (.erc20, .ethereum): return tradeManager.swapExactTokensForETH(amountIn: amountIn, amountOutMin: amountOutMin, path: path)
//            case (.erc20, .erc20): return tradeManager.swapExactTokensForETH(amountIn: amountIn, amountOutMin: amountOutMin, path: path)
            default: fatalError()
            }
        } catch {
            return Single.error(error)
        }
    }

    public func swapItemForExactItem(pathItems: [PathItem]) -> Single<String> {
        do {
            let path = try pathItems.map { try address(item: $0.swapItem) }

            guard let fromPathItem = pathItems.first else {
                throw KitError.invalidPathItems
            }

            guard let toPathItem = pathItems.last else {
                throw KitError.invalidPathItems
            }

            let amountInMax = try convert(amount: fromPathItem.amount)
            let amountOut = try convert(amount: toPathItem.amount)

            switch (fromPathItem.swapItem, toPathItem.swapItem) {
            case (.ethereum, .erc20): return tradeManager.swapETHForExactTokens(amountOut: amountOut, amountInMax: amountInMax, path: path)
            case (.erc20, .ethereum): return tradeManager.swapTokensForExactETH(amountOut: amountOut, amountInMax: amountInMax, path: path)
//            case (.erc20, .erc20): return tradeManager.swapExactTokensForETH(amountIn: amountIn, amountOutMin: amountOutMin, path: path)
            default: fatalError()
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

        guard let wethAddress = Data(hex: wethContractAddress) else {
            throw KitError.invalidAddress
        }

        let tradeManager = TradeManager(ethereumKit: ethereumKit, routerAddress: routerAddress, address: address)

        let uniswapKit = Kit(ethereumKit: ethereumKit, tradeManager: tradeManager, wethAddress: wethAddress)

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

public enum SwapItem {
    case ethereum
    case erc20(contractAddress: String)
}

extension SwapItem: Equatable {

    public static func ==(lhs: SwapItem, rhs: SwapItem) -> Bool {
        switch (lhs, rhs) {
        case (.ethereum, .ethereum): return true
        case (.erc20(let lhsContractAddress), .erc20(let rhsContractAddress)): return lhsContractAddress == rhsContractAddress
        default: return false
        }
    }

}

public struct PathItem {
    public let swapItem: SwapItem
    public let amount: String
}
