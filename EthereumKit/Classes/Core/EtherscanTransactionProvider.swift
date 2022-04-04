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

    private func apiSingle(params: [String: Any]) -> Single<[[String: String]]> {
        let urlString = "\(baseUrl)/api"

        var parameters = params
        parameters["apikey"] = apiKey

        return networkManager.single(url: urlString, method: .get, parameters: parameters, mapper: self, responseCacherBehavior: .doNotCache)
    }

    private func providerTransaction(data: [String: String]) -> ProviderTransaction? {
        guard let blockNumber = data["blockNumber"].flatMap({ Int($0) }) else { return nil }
        guard let timestamp = data["timeStamp"].flatMap({ Int($0) }) else { return nil }
        guard let hash = data["hash"].flatMap({ Data(hex: $0) }) else { return nil }
        guard let nonce = data["nonce"].flatMap({ Int($0) }) else { return nil }
        guard let transactionIndex = data["transactionIndex"].flatMap({ Int($0) }) else { return nil }
        guard let from = data["from"].flatMap({ Data(hex: $0) }).map({ Address(raw: $0) }) else { return nil }
        guard let toData = data["to"].flatMap({ Data(hex: $0) }) else { return nil }
        guard let value = data["value"].flatMap({ BigUInt($0) }) else { return nil }
        guard let gasLimit = data["gas"].flatMap({ Int($0) }) else { return nil }
        guard let gasPrice = data["gasPrice"].flatMap({ Int($0) }) else { return nil }
        guard let input = data["input"].flatMap({ Data(hex: $0) }) else { return nil }

        return ProviderTransaction(
                blockNumber: blockNumber,
                timestamp: timestamp,
                hash: hash,
                nonce: nonce,
                blockHash: data["blockHash"].flatMap({ Data(hex: $0) }),
                transactionIndex: transactionIndex,
                from: from,
                to: toData.count > 0 ? Address(raw: toData) : nil,
                value: value,
                gasLimit: gasLimit,
                gasPrice: gasPrice,
                isError: data["isError"].flatMap { Int($0) },
                txReceiptStatus: data["txreceipt_status"].flatMap { Int($0) },
                input: input,
                cumulativeGasUsed: data["cumulativeGasUsed"].flatMap { Int($0) },
                gasUsed: data["gasUsed"].flatMap { Int($0) }
        )
    }

    private func internalTransaction(data: [String: String]) -> ProviderInternalTransaction? {
        guard let hash = data["hash"].flatMap({ Data(hex: $0) }) else { return nil }
        guard let blockNumber = data["blockNumber"].flatMap({ Int($0) }) else { return nil }
        guard let timestamp = data["timeStamp"].flatMap({ Int($0) }) else { return nil }
        guard let from = data["from"].flatMap({ Data(hex: $0) }).map({ Address(raw: $0) }) else { return nil }
        guard let to = data["to"].flatMap({ Data(hex: $0) }).map({ Address(raw: $0) }) else { return nil }
        guard let value = data["value"].flatMap({ BigUInt($0) }) else { return nil }
        guard let traceId = data["traceId"] else { return nil }

        return ProviderInternalTransaction(
                hash: hash,
                blockNumber: blockNumber,
                timestamp: timestamp,
                from: from,
                to: to,
                value: value,
                traceId: traceId
        )
    }

    private func providerTokenTransaction(data: [String: String]) -> ProviderTokenTransaction? {
        guard let blockNumber = data["blockNumber"].flatMap({ Int($0) }) else { return nil }
        guard let timestamp = data["timeStamp"].flatMap({ Int($0) }) else { return nil }
        guard let hash = data["hash"].flatMap({ Data(hex: $0) }) else { return nil }
        guard let nonce = data["nonce"].flatMap({ Int($0) }) else { return nil }
        guard let blockHash = data["blockHash"].flatMap({ Data(hex: $0) }) else { return nil }
        guard let from = data["from"].flatMap({ Data(hex: $0) }).map({ Address(raw: $0) }) else { return nil }
        guard let contractAddress = data["contractAddress"].flatMap({ Data(hex: $0) }).map({ Address(raw: $0) }) else { return nil }
        guard let to = data["to"].flatMap({ Data(hex: $0) }).map({ Address(raw: $0) }) else { return nil }
        guard let value = data["value"].flatMap({ BigUInt($0) }) else { return nil }
        guard let tokenName = data["tokenName"] else { return nil }
        guard let tokenSymbol = data["tokenSymbol"] else { return nil }
        guard let tokenDecimal = data["tokenDecimal"].flatMap({ Int($0) }) else { return nil }
        guard let transactionIndex = data["transactionIndex"].flatMap({ Int($0) }) else { return nil }
        guard let gasLimit = data["gas"].flatMap({ Int($0) }) else { return nil }
        guard let gasPrice = data["gasPrice"].flatMap({ Int($0) }) else { return nil }
        guard let gasUsed = data["gasUsed"].flatMap({ Int($0) }) else { return nil }
        guard let cumulativeGasUsed = data["cumulativeGasUsed"].flatMap({ Int($0) }) else { return nil }

        return ProviderTokenTransaction(
                blockNumber: blockNumber,
                timestamp: timestamp,
                hash: hash,
                nonce: nonce,
                blockHash: blockHash,
                from: from,
                contractAddress: contractAddress,
                to: to,
                value: value,
                tokenName: tokenName,
                tokenSymbol: tokenSymbol,
                tokenDecimal: tokenDecimal,
                transactionIndex: transactionIndex,
                gasLimit: gasLimit,
                gasPrice: gasPrice,
                gasUsed: gasUsed,
                cumulativeGasUsed: cumulativeGasUsed
        )
    }

}

extension EtherscanTransactionProvider: ITransactionProvider {

    func transactionsSingle(startBlock: Int) -> Single<[ProviderTransaction]> {
        let params: [String: Any] = [
            "module": "account",
            "action": "txlist",
            "address": address.hex,
            "startblock": startBlock,
            "endblock": 99999999,
            "sort": "desc"
        ]

        return apiSingle(params: params).map { [weak self] array -> [ProviderTransaction] in
            array.compactMap { self?.providerTransaction(data: $0) }
        }
    }

    func internalTransactionsSingle(startBlock: Int) -> Single<[ProviderInternalTransaction]> {
        let params: [String: Any] = [
            "module": "account",
            "action": "txlistinternal",
            "address": address.hex,
            "startblock": startBlock,
            "endblock": 99999999,
            "sort": "desc"
        ]

        return apiSingle(params: params).map { [weak self] array -> [ProviderInternalTransaction] in
            array.compactMap { self?.internalTransaction(data: $0) }
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
            array.compactMap { self?.internalTransaction(data: $0) }
        }
    }

    func tokenTransactionsSingle(startBlock: Int) -> Single<[ProviderTokenTransaction]> {
        let params: [String: Any] = [
            "module": "account",
            "action": "tokentx",
            "address": address.hex,
            "startblock": startBlock,
            "endblock": 99999999,
            "sort": "desc"
        ]

        return apiSingle(params: params).map { [weak self] array -> [ProviderTokenTransaction] in
            array.compactMap { self?.providerTokenTransaction(data: $0) }
        }
    }

}

extension EtherscanTransactionProvider: IApiMapper {

    public func map(statusCode: Int, data: Any?) throws -> [[String: String]] {
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

        guard let result = map["result"] as? [[String: String]] else {
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
