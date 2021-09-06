import EthereumKit
import HsToolKit
import BigInt
import RxSwift

class OneInchProvider {
    private static let notEnoughEthErrors = ["Try to leave the buffer of ETH for gas", "you may not have enough ETH balance for gas fee", "Not enough ETH balance"]
    private let networkManager: NetworkManager
    private let networkType: NetworkType

    private var url: String { "https://unstoppable.api.enterprise.1inch.exchange/v3.0/\(networkType.chainId)/" }

    init(networkManager: NetworkManager, networkType: NetworkType) {
        self.networkManager = networkManager
        self.networkType = networkType
    }

    private func params(dictionary: [String: Any?]) -> [String: Any] {
        var result = [String: Any]()

        dictionary.forEach { key, value in
                    if let value = value {
                        result[key] = value
                    }
                }

        return result
    }

    private static func notEnoughErrorContains(in message: String) -> Bool {
        for error in notEnoughEthErrors {
            if message.contains(error) { return true }
        }

        return false
    }

}

extension OneInchProvider {

    func approveCallDataSingle(tokenAddress: Address, amount: BigUInt?, infinity: Bool? = nil) -> Single<ApproveCallData> {
        var parameters: [String: Any] = ["tokenAddress": tokenAddress]
        if let amount = amount {
            parameters["amount"] = amount.description
        }
        if let infinity = infinity {
            parameters["infinity"] = infinity
        }

        let mapper = ApproveCallDataMapper()
        return networkManager.single(url: url + "approve/calldata", method: .get, parameters: parameters, mapper: mapper, responseCacherBehavior: .doNotCache)
    }

    func approveSpenderSingle() -> Single<Spender> {
        networkManager.single(url: url + "approve/spender", method: .get, parameters: [:], mapper: SpenderMapper(), responseCacherBehavior: .doNotCache)
    }

    func quoteSingle(fromToken: Address,
                     toToken: Address,
                     amount: BigUInt,
                     protocols: String? = nil,
                     gasPrice: Int? = nil,
                     complexityLevel: Int? = nil,
                     connectorTokens: String? = nil,
                     gasLimit: Int? = nil,
                     mainRouteParts: Int? = nil,
                     parts: Int? = nil) -> Single<Quote> {

       let parameters = params(dictionary:
       [
           "fromTokenAddress": fromToken,
           "toTokenAddress": toToken,
           "amount": amount.description,
           "protocols": protocols,
           "connectorTokens": connectorTokens,
           "gasPrice": gasPrice,
           "complexityLevel": complexityLevel,
           "gasLimit": gasLimit,
           "mainRouteParts": mainRouteParts,
           "parts": parts,
       ])

        let mapper = QuoteMapper(tokenMapper: TokenMapper())
        return networkManager.single(url: url + "quote", method: .get, parameters: parameters, mapper: mapper, responseCacherBehavior: .doNotCache)
    }

    func swapSingle(fromToken: String,
                     toToken: String,
                     amount: BigUInt,
                     fromAddress: String,
                     slippage: Decimal,
                     protocols: String? = nil,
                     recipient: String? = nil,
                     gasPrice: Int? = nil,
                     burnChi: Bool? = nil,
                     complexityLevel: Int? = nil,
                     connectorTokens: String? = nil,
                     allowPartialFill: Bool? = nil,
                     gasLimit: Int? = nil,
                     mainRouteParts: Int? = nil,
                     parts: Int? = nil) -> Single<Swap> {

       let parameters = params(dictionary:
       [
           "fromTokenAddress": fromToken,
           "toTokenAddress": toToken,
           "amount": amount.description,
           "fromAddress": fromAddress,
           "slippage": slippage,
           "protocols": protocols,
           "destReceiver": recipient,
           "gasPrice": gasPrice,
           "burnChi": burnChi,
           "complexityLevel": complexityLevel,
           "connectorTokens": connectorTokens,
           "allowPartialFill": allowPartialFill,
           "gasLimit": gasLimit,
           "mainRouteParts": mainRouteParts,
           "parts": parts,
       ])

        let tokenMapper = TokenMapper()
        let mapper = SwapMapper(tokenMapper: tokenMapper, swapTransactionMapper: SwapTransactionMapper(tokenMapper: tokenMapper))

        return networkManager
                .single(url: url + "swap", method: .get, parameters: parameters, mapper: mapper, responseCacherBehavior: .doNotCache)
                .catchError { error in
                    if case let .invalidResponse(_, data) = (error as? NetworkManager.RequestError),
                       let dictionary = data as? [String: Any],
                       let message = dictionary["message"] as? String {
                        if Self.notEnoughErrorContains(in: message) {
                            return Single.error(Kit.SwapError.notEnough)
                        } else if message.contains("cannot estimate") {
                            return Single.error(Kit.SwapError.cannotEstimate)
                        }
                    }

                    return Single.error(error)
                }
    }

}
