import RxSwift
import EthereumKit
import BigInt
import HsToolKit

public class Kit {
    private let disposeBag = DisposeBag()

    private let evmKit: EthereumKit.Kit
    private let provider: OneInchProvider

    init(evmKit: EthereumKit.Kit, provider: OneInchProvider) {
        self.evmKit = evmKit
        self.provider = provider
    }

}

extension Kit {

    public var routerAddress: Address {
        switch evmKit.networkType {
        case .ethMainNet, .bscMainNet: return try! Address(hex: "0x11111112542d85b3ef69ae05771c2dccff4faa26")
        default: return try! Address(hex: "0x11111112542d85b3ef69ae05771c2dccff4faa26") // todo: testnet
        }
    }

    public func approveCallDataSingle(tokenAddress: Address, amount: BigUInt?, infinity: Bool? = nil) -> Single<ApproveCallData> {
        provider.approveCallDataSingle(tokenAddress: tokenAddress, amount: amount, infinity: infinity)
    }

    public func quoteSingle(fromToken: Address,
                            toToken: Address,
                            amount: BigUInt,
                            protocols: String? = nil,
                            gasPrice: Int? = nil,
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
                    gasPrice: Int? = nil,
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

    public static func instance(evmKit: EthereumKit.Kit) -> Kit {
        let logger = Logger(minLogLevel: .debug)
        let networkManager = NetworkManager(logger: logger)
        let provider = OneInchProvider(networkManager: networkManager, networkType: evmKit.networkType)


        let oneInchKit = Kit(evmKit: evmKit, provider: provider)

        return oneInchKit
    }


    public static func addDecorator(to evmKit: EthereumKit.Kit) {
        evmKit.add(decorator: OneInchTransactionDecorator(address: evmKit.address, contractMethodFactories: OneInchContractMethodFactories.shared))
    }

    public static func addTransactionWatcher(to evmKit: EthereumKit.Kit) {
        evmKit.add(transactionWatcher: OneInchTransactionWatcher(address: evmKit.address))
    }

}

extension Kit {

    public enum NetworkTypeError: Error {
        case invalid
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
