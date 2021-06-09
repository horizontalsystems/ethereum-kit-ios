import EthereumKit
import BigInt
import HsToolKit

struct ApproveCallDataMapper: IApiMapper {
    typealias T = ApproveCallData

    func map(statusCode: Int, data: Any?) throws -> T {
        guard let map = data as? [String: Any] else {
            throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
        }

        guard let dataString = map["data"] as? String,
              let data = Data(hex: dataString),
              let toString = map["to"] as? String,
              let to = try? Address(hex: toString),
              let gasPriceString = map["gasPrice"] as? String,
              let gasPrice = Int(gasPriceString),
              let valueString = map["value"] as? String,
              let value = BigUInt(valueString, radix: 10) else {

            throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
        }

        return T(data: data, gasPrice: gasPrice, to: to, value: value)
    }

}
