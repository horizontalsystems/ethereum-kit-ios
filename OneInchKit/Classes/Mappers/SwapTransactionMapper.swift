import BigInt
import HsToolKit
import EthereumKit

struct SwapTransactionMapper: IApiMapper {
    typealias T = SwapTransaction

    private let tokenMapper: TokenMapper

    init(tokenMapper: TokenMapper) {
        self.tokenMapper = tokenMapper
    }

    func map(statusCode: Int, data: Any?) throws -> T {
        guard let map = data as? [String: Any] else {
            throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
        }

        guard let fromString = map["from"] as? String,
              let from = try? Address(hex: fromString),
              let toString = map["to"] as? String,
              let to = try? Address(hex: toString),
              let dataString = map["data"] as? String,
              let data = Data(hex: dataString),
              let valueSting = map["value"] as? String,
              let value = BigUInt(valueSting, radix: 10),
              let gasPriceString = map["gasPrice"] as? String,
              let gasPrice = Int(gasPriceString),
              let gasLimit = map["gas"] as? Int else {

            throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
        }

        return T(from: from,
                to: to,
                data: data,
                value: value,
                gasPrice: gasPrice,
                gasLimit: gasLimit)
    }

}
