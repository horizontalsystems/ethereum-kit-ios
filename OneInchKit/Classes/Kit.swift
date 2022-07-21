import RxSwift
import EthereumKit
import BigInt
import HsToolKit

public class Kit {
    public let routerAddress: Address

    private let evmKit: EthereumKit.Kit
    private let provider: OneInchProvider

    init(routerAddress: Address, evmKit: EthereumKit.Kit, provider: OneInchProvider) {
        self.routerAddress = routerAddress
        self.evmKit = evmKit
        self.provider = provider
    }

}

extension Kit {

    public func approveCallDataSingle(tokenAddress: Address, amount: BigUInt?, infinity: Bool? = nil) -> Single<ApproveCallData> {
        provider.approveCallDataSingle(tokenAddress: tokenAddress, amount: amount, infinity: infinity)
    }

    public func quoteSingle(fromToken: Address,
                            toToken: Address,
                            amount: BigUInt,
                            protocols: String? = nil,
                            gasPrice: GasPrice? = nil,
                            complexityLevel: Int? = nil,
                            connectorTokens: String? = nil,
                            gasLimit: Int? = nil,
                            mainRouteParts: Int? = nil,
                            parts: Int? = nil) -> Single<Quote> {

        provider.quoteSingle(
                fromToken: fromToken,
                toToken: toToken,
                amount: amount,
                protocols: protocols,
                gasPrice: gasPrice,
                complexityLevel: complexityLevel,
                connectorTokens: connectorTokens,
                gasLimit: gasLimit,
                mainRouteParts: mainRouteParts,
                parts: parts)
    }

    public func swapSingle(fromToken: Address,
                    toToken: Address,
                    amount: BigUInt,
                    slippage: Decimal,
                    protocols: [String]? = nil,
                    recipient: Address? = nil,
                    gasPrice: GasPrice? = nil,
                    burnChi: Bool? = nil,
                    complexityLevel: Int? = nil,
                    connectorTokens: [String]? = nil,
                    allowPartialFill: Bool? = nil,
                    gasLimit: Int? = nil,
                    mainRouteParts: Int? = nil,
                    parts: Int? = nil) -> Single<Swap> {

        provider.swapSingle(fromToken: fromToken.hex,
                toToken: toToken.hex,
                amount: amount,
                fromAddress: evmKit.receiveAddress.hex,
                slippage: slippage,
                protocols: protocols?.joined(separator: ","),
                recipient: recipient?.hex,
                gasPrice: gasPrice,
                burnChi: burnChi,
                complexityLevel: complexityLevel,
                connectorTokens: connectorTokens?.joined(separator: ","),
                allowPartialFill: allowPartialFill,
                gasLimit: gasLimit,
                mainRouteParts: mainRouteParts,
                parts: parts)
    }

}

extension Kit {

    public static func instance(evmKit: EthereumKit.Kit, minLogLevel: Logger.Level = .error) throws -> Kit {
        let logger = Logger(minLogLevel: minLogLevel)
        let networkManager = NetworkManager(logger: logger)

        let oneInchKit = Kit(
                routerAddress: try routerAddress(chain: evmKit.chain),
                evmKit: evmKit,
                provider: OneInchProvider(networkManager: networkManager, chain: evmKit.chain)
        )

        return oneInchKit
    }


    public static func addDecorators(to evmKit: EthereumKit.Kit) {
        evmKit.add(methodDecorator: OneInchMethodDecorator(contractMethodFactories: OneInchContractMethodFactories.shared))
        evmKit.add(transactionDecorator: OneInchTransactionDecorator(address: evmKit.address))
    }

    private static func routerAddress(chain: Chain) throws -> Address {
        switch chain.id {
        case 1, 56, 137, 42161, 43114: return try Address(hex: "0x1111111254fb6c44bac0bed2854e76f90643097d")
        case 10: return try Address(hex: "0x1111111254760f7ab3f16433eea9304126dcd199")
        case 3, 4, 5, 42: return try Address(hex: "0x11111112542d85b3ef69ae05771c2dccff4faa26")
        default: throw UnsupportedChainError.noRouterAddress
        }
    }

}

extension Kit {

    public enum UnsupportedChainError: Error {
        case noRouterAddress
    }

    public enum QuoteError: Error {
        case insufficientLiquidity
    }

    public enum SwapError: Error {
        case notEnough
        case cannotEstimate
    }

}

extension BigUInt {

    public func toDecimal(decimals: Int) -> Decimal? {
        guard let decimalValue = Decimal(string: description) else {
            return nil
        }

        return decimalValue / pow(10, decimals)
    }

}
