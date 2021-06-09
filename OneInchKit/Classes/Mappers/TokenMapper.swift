import HsToolKit

public struct TokenMapper: IApiMapper {
    public typealias T = Token

    public func map(statusCode: Int, data: Any?) throws -> T {
        guard let map = data as? [String: Any] else {
            throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
        }

        guard let symbol = map["symbol"] as? String,
              let name = map["name"] as? String,
              let decimals = map["decimals"] as? Int,
              let address = map["address"] as? String,
              let logoUri = map["logoURI"] as? String else {

            throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
        }

        return T(symbol: symbol, name: name, decimals: decimals, address: address, logoUri: logoUri)
    }

}
