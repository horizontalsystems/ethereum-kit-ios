import RxSwift
import BigInt
import Alamofire

public class EtherscanApiProvider {
    private let networkManager: NetworkManager
    private let network: INetwork

    private let etherscanApiKey: String
    private let address: Data

    private let rateLimitRetrier = RateLimitRetrier()

    init(networkManager: NetworkManager, network: INetwork, etherscanApiKey: String, address: Data) {
        self.networkManager = networkManager
        self.network = network
        self.etherscanApiKey = etherscanApiKey
        self.address = address
    }

    private var baseUrl: String {
        switch network {
        case is Ropsten: return "https://ropsten.etherscan.io"
        case is Kovan: return "https://kovan.etherscan.io"
        default: return "https://api.etherscan.io"
        }
    }

    private func apiSingle(params: [String: Any]) -> Single<[[String: String]]> {
        let urlString = "\(baseUrl)/api"

        var parameters = params
        parameters["apikey"] = etherscanApiKey

        let request = networkManager.session.request(urlString, method: .get, parameters: parameters, interceptor: rateLimitRetrier)

        return networkManager.single(request: request)
                { data throws -> [[String: String]] in
                    guard let map = data as? [String: Any] else {
                        throw ApiError.invalidResponse
                    }

                    guard let status = map["status"] as? String else {
                        throw ApiError.invalidStatus
                    }

                    guard status == "1" else {
                        let message = map["message"] as? String
                        let result = map["result"] as? String

                        // Etherscan API returns status 0 if no transactions found.
                        // It is not error case, so we should not throw an error.
                        if message == "No transactions found" {
                            return []
                        }

                        throw ApiError.responseError(message: message, result: result)
                    }

                    guard let result = map["result"] as? [[String: String]] else {
                        throw ApiError.invalidResult
                    }

                    return result
                }
    }

}

extension EtherscanApiProvider {

    public func transactionsSingle(startBlock: Int) -> Single<[[String: String]]> {
        let params: [String: Any] = [
            "module": "account",
            "action": "txlist",
            "address": address.toHexString(),
            "startblock": startBlock,
            "endblock": 99999999,
            "sort": "desc"
        ]

        return apiSingle(params: params)
    }

    public func tokenTransactionsSingle(contractAddress: Data, startBlock: Int) -> Single<[[String: String]]> {
        let params: [String: Any] = [
            "module": "account",
            "action": "tokentx",
            "contractaddress": contractAddress.toHexString(),
            "address": address.toHexString(),
            "startblock": startBlock,
            "endblock": 99999999,
            "sort": "desc"
        ]

        return apiSingle(params: params)
    }

}

class EtherscanTransactionProvider: ITransactionsProvider {
    private let provider: EtherscanApiProvider

    init(provider: EtherscanApiProvider) {
        self.provider = provider
    }

    var source: String {
        "etherscan.io"
    }

    func transactionsSingle(startBlock: Int) -> Single<[Transaction]> {
        provider.transactionsSingle(startBlock: startBlock).map { array -> [Transaction] in
            array.compactMap { data -> Transaction? in
                guard let hash = data["hash"].flatMap({ Data(hex: $0) }) else { return nil }
                guard let nonce = data["nonce"].flatMap({ Int($0) }) else { return nil }
                guard let from = data["from"].flatMap({ Data(hex: $0) }) else { return nil }
                guard let to = data["to"].flatMap({ Data(hex: $0) }) else { return nil }
                guard let value = data["value"].flatMap({ BigUInt($0) }) else { return nil }
                guard let gasLimit = data["gas"].flatMap({ Int($0) }) else { return nil }
                guard let gasPrice = data["gasPrice"].flatMap({ Int($0) }) else { return nil }
                guard let input = data["input"].flatMap({ Data(hex: $0) }) else { return nil }
                guard let timestamp = data["timeStamp"].flatMap({ Double($0) }) else { return nil }

                let transaction = Transaction(hash: hash, nonce: nonce, input: input, from: from, to: to, value: value, gasLimit: gasLimit, gasPrice: gasPrice, timestamp: timestamp)

                transaction.blockHash = data["blockHash"].flatMap({ Data(hex: $0) })
                transaction.blockNumber = data["blockNumber"].flatMap { Int($0) }
                transaction.gasUsed = data["gasUsed"].flatMap { Int($0) }
                transaction.cumulativeGasUsed = data["cumulativeGasUsed"].flatMap { Int($0) }
                transaction.isError = data["isError"].flatMap { Int($0) }
                transaction.transactionIndex = data["transactionIndex"].flatMap { Int($0) }
                transaction.txReceiptStatus = data["txreceipt_status"].flatMap { Int($0) }

                return transaction
            }
        }
    }

}

extension EtherscanApiProvider {

    public enum ApiError: Error {
        case invalidResponse
        case invalidStatus
        case responseError(message: String?, result: String?)
        case invalidResult
    }

}

extension EtherscanApiProvider {

    class RateLimitRetrier: RequestInterceptor {

        func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> ()) {
            if case let AFError.responseSerializationFailed(reason) = error,
               case let .customSerializationFailed(serializationError) = reason,
               case let ApiError.responseError(message, result) = serializationError,
               message == "NOTOK", result == "Max rate limit reached"
            {
                completion(.retryWithDelay(1))
            } else {
                completion(.doNotRetry)
            }
        }

    }

}
