import BigInt
import HsToolKit

struct SwapMapper: IApiMapper {
    typealias T =  Swap

    private let tokenMapper: TokenMapper
    private let swapTransactionMapper: SwapTransactionMapper

    init(tokenMapper: TokenMapper, swapTransactionMapper: SwapTransactionMapper) {
        self.tokenMapper = tokenMapper
        self.swapTransactionMapper = swapTransactionMapper
    }

    func map(statusCode: Int, data: Any?) throws -> T {
        guard let map = data as? [String: Any] else {
            throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
        }

        guard let fromTokenMap = map["fromToken"] as? [String: Any],
              let toTokenMap = map["toToken"] as? [String: Any],
              let transactionMap = map["tx"] as? [String: Any] else {

            throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
        }

        let fromToken = try tokenMapper.map(statusCode: statusCode, data: fromTokenMap)
        let toToken = try tokenMapper.map(statusCode: statusCode, data: toTokenMap)
        let transaction = try swapTransactionMapper.map(statusCode: statusCode, data: transactionMap)

        guard let toAmountString = map["toTokenAmount"] as? String,
              let toAmount = BigUInt(toAmountString, radix: 10),
              let fromAmountString = map["fromTokenAmount"] as? String,
              let fromAmount = BigUInt(fromAmountString, radix: 10) else {

            throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
        }


        return T(fromToken: fromToken,
                toToken: toToken,
                fromTokenAmount: fromAmount,
                toTokenAmount: toAmount,
                route: [],                      // todo: parse "protocols"
                transaction: transaction)
    }

}
