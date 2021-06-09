import EthereumKit
import BigInt
import HsToolKit

struct QuoteMapper: IApiMapper {
    typealias T = Quote

    private let tokenMapper: TokenMapper

    init(tokenMapper: TokenMapper) {
        self.tokenMapper = tokenMapper
    }

    func map(statusCode: Int, data: Any?) throws -> T {
        guard let map = data as? [String: Any] else {
            throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
        }

        guard let fromTokenMap = map["fromToken"] as? [String: Any],
              let toTokenMap = map["toToken"] as? [String: Any] else {
            throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
        }

        let fromToken = try tokenMapper.map(statusCode: statusCode, data: fromTokenMap)
        let toToken = try tokenMapper.map(statusCode: statusCode, data: toTokenMap)

        guard let toAmountString = map["toTokenAmount"] as? String,
              let toAmount = BigUInt(toAmountString, radix: 10),
              let fromAmountString = map["fromTokenAmount"] as? String,
              let fromAmount = BigUInt(fromAmountString, radix: 10),
              let estimateGas = map["estimatedGas"] as? Int else {

            throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
        }


        return T(fromToken: fromToken,
                toToken: toToken,
                fromTokenAmount: fromAmount,
                toTokenAmount: toAmount,
                route: [],                      // todo: parse "protocols"
                estimateGas: estimateGas)
    }

}
