import RxSwift
import BigInt
import Alamofire
import HsToolKit

class EtherscanTransactionProvider {
    private let networkManager: SerialNetworkManager
    private let baseUrl: String
    private let apiKey: String
    private let address: Address

    init(baseUrl: String, apiKey: String, address: Address, logger: Logger) {
        networkManager = SerialNetworkManager(requestInterval: 1, logger: logger)
        self.baseUrl = baseUrl
        self.apiKey = apiKey
        self.address = address
    }

    private func apiSingle(params: [String: Any]) -> Single<[[String: Any]]> {
        let urlString = "\(baseUrl)/api"

        var parameters = params
        parameters["apikey"] = apiKey

        return networkManager.single(url: urlString, method: .get, parameters: parameters, mapper: self, responseCacherBehavior: .doNotCache)
    }

}

extension EtherscanTransactionProvider: ITransactionProvider {

    func transactionsSingle(startBlock: Int) -> Single<[ProviderTransaction]> {
        let params: [String: Any] = [
            "module": "account",
            "action": "txlist",
            "address": address.hex,
            "startblock": startBlock,
            "sort": "desc"
        ]

        return apiSingle(params: params).map { [weak self] array -> [ProviderTransaction] in
            array.compactMap { try? ProviderTransaction(JSON: $0) }
        }
    }

    func internalTransactionsSingle(startBlock: Int) -> Single<[ProviderInternalTransaction]> {
        let params: [String: Any] = [
            "module": "account",
            "action": "txlistinternal",
            "address": address.hex,
            "startblock": startBlock,
            "sort": "desc"
        ]

        return apiSingle(params: params).map { [weak self] array -> [ProviderInternalTransaction] in
            array.compactMap { try? ProviderInternalTransaction(JSON: $0) }
        }
    }

    func internalTransactionsSingle(transactionHash: Data) -> Single<[ProviderInternalTransaction]> {
        let params: [String: Any] = [
            "module": "account",
            "action": "txlistinternal",
            "txhash": transactionHash.toHexString(),
            "sort": "desc"
        ]

        return apiSingle(params: params).map { [weak self] array -> [ProviderInternalTransaction] in
            array.compactMap { try? ProviderInternalTransaction(JSON: $0) }
        }
    }

    func tokenTransactionsSingle(startBlock: Int) -> Single<[ProviderTokenTransaction]> {
        let params: [String: Any] = [
            "module": "account",
            "action": "tokentx",
            "address": address.hex,
            "startblock": startBlock,
            "sort": "desc"
        ]

        return apiSingle(params: params).map { [weak self] array -> [ProviderTokenTransaction] in
            array.compactMap { try? ProviderTokenTransaction(JSON: $0) }
        }
    }

    public func eip721TransactionsSingle(startBlock: Int) -> Single<[ProviderEip721Transaction]> {
        let params: [String: Any] = [
            "module": "account",
            "action": "tokennfttx",
            "address": address.hex,
            "startblock": startBlock,
            "sort": "desc"
        ]

        return apiSingle(params: params).map { [weak self] array -> [ProviderEip721Transaction] in
            array.compactMap { try? ProviderEip721Transaction(JSON: $0) }
        }
    }

    public func eip1155TransactionsSingle(startBlock: Int) -> Single<[ProviderEip1155Transaction]> {
        let params: [String: Any] = [
            "module": "account",
            "action": "token1155tx",
            "address": address.hex,
            "startblock": startBlock,
            "sort": "desc"
        ]

        return apiSingle(params: params).map { [weak self] array -> [ProviderEip1155Transaction] in
            array.compactMap { try? ProviderEip1155Transaction(JSON: $0) }
        }
    }

}

extension EtherscanTransactionProvider: IApiMapper {

    public func map(statusCode: Int, data: Any?) throws -> [[String: Any]] {
        guard let map = data as? [String: Any] else {
            throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
        }

        guard let status = map["status"] as? String else {
            throw RequestError.invalidStatus
        }

        guard status == "1" else {
            let message = map["message"] as? String
            let result = map["result"] as? String

            // Etherscan API returns status 0 if no transactions found.
            // It is not error case, so we should not throw an error.
            if message == "No transactions found" {
                return []
            }

            if message == "NOTOK", let result = result, result.contains("Max rate limit reached") {
                throw RequestError.rateLimitExceeded
            }

            throw RequestError.responseError(message: message, result: result)
        }

        guard let result = map["result"] as? [[String: Any]] else {
            throw RequestError.invalidResult
        }

        return result
    }

}

extension EtherscanTransactionProvider {

    public enum RequestError: Error {
        case invalidStatus
        case responseError(message: String?, result: String?)
        case invalidResult
        case rateLimitExceeded
    }

}
