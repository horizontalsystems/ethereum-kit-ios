import RxSwift
import BigInt
import Alamofire
import HsToolKit

public class EtherscanService {
    private let networkManager: SerialNetworkManager
    private let networkType: NetworkType

    private let etherscanApiKey: String
    private let address: Address

    init(networkType: NetworkType, etherscanApiKey: String, address: Address, logger: Logger) {
        self.networkManager = SerialNetworkManager(requestInterval: 1, logger: logger)
        self.networkType = networkType
        self.etherscanApiKey = etherscanApiKey
        self.address = address
    }

    private var baseUrl: String {
        switch networkType {
        case .ethMainNet: return "https://api.etherscan.io"
        case .bscMainNet: return "https://api.bscscan.com"
        case .ropsten: return "https://api-ropsten.etherscan.io"
        case .rinkeby: return "https://api-rinkeby.etherscan.io"
        case .kovan: return "https://api-kovan.etherscan.io"
        case .goerli: return "https://api-goerli.etherscan.io"
        }
    }

    private func apiSingle(params: [String: Any]) -> Single<[[String: String]]> {
        let urlString = "\(baseUrl)/api"

        var parameters = params
        parameters["apikey"] = etherscanApiKey

        return networkManager.single(url: urlString, method: .get, parameters: parameters, mapper: self, responseCacherBehavior: .doNotCache)
    }

}

extension EtherscanService {

    public func transactionsSingle(startBlock: Int) -> Single<[[String: String]]> {
        let params: [String: Any] = [
            "module": "account",
            "action": "txlist",
            "address": address.hex,
            "startblock": startBlock,
            "endblock": 99999999,
            "sort": "desc"
        ]

        return apiSingle(params: params)
    }

    public func internalTransactionsSingle(startBlock: Int) -> Single<[[String: String]]> {
        let params: [String: Any] = [
            "module": "account",
            "action": "txlistinternal",
            "address": address.hex,
            "startblock": startBlock,
            "endblock": 99999999,
            "sort": "desc"
        ]

        return apiSingle(params: params)
    }

    public func tokenTransactionsSingle(startBlock: Int) -> Single<[[String: String]]> {
        let params: [String: Any] = [
            "module": "account",
            "action": "tokentx",
            "address": address.hex,
            "startblock": startBlock,
            "endblock": 99999999,
            "sort": "desc"
        ]

        return apiSingle(params: params)
    }

    func internalTransactionsSingle(transactionHash: Data) -> Single<[[String: String]]> {
        let params: [String: Any] = [
            "module": "account",
            "action": "txlistinternal",
            "txhash": transactionHash.toHexString(),
            "sort": "desc"
        ]

        return apiSingle(params: params)
    }

}

class EtherscanTransactionProvider {
    private let etherscanService: EtherscanService

    init(service: EtherscanService) {
        etherscanService = service
    }

    var source: String {
        "etherscan.io"
    }

    func transactionsSingle(startBlock: Int) -> Single<[EtherscanTransaction]> {
        etherscanService.transactionsSingle(startBlock: startBlock).map { array -> [EtherscanTransaction] in
            array.compactMap { data -> EtherscanTransaction? in
                guard let hash = data["hash"].flatMap({ Data(hex: $0) }) else { return nil }
                guard let nonce = data["nonce"].flatMap({ Int($0) }) else { return nil }
                guard let from = data["from"].flatMap({ Data(hex: $0) }).map({ Address(raw: $0) }) else { return nil }
                guard let to = data["to"].flatMap({ Data(hex: $0) }).map({ Address(raw: $0) }) else { return nil }
                guard let value = data["value"].flatMap({ BigUInt($0) }) else { return nil }
                guard let gasLimit = data["gas"].flatMap({ Int($0) }) else { return nil }
                guard let gasPrice = data["gasPrice"].flatMap({ Int($0) }) else { return nil }
                guard let input = data["input"].flatMap({ Data(hex: $0) }) else { return nil }
                guard let timestamp = data["timeStamp"].flatMap({ Int($0) }) else { return nil }

                let transaction = EtherscanTransaction(hash: hash, nonce: nonce, input: input, from: from, to: to, value: value, gasLimit: gasLimit, gasPrice: gasPrice, timestamp: timestamp)

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

    func internalTransactionsSingle(startBlock: Int) -> Single<[InternalTransaction]> {
        etherscanService.internalTransactionsSingle(startBlock: startBlock).map { array -> [InternalTransaction] in
            array.compactMap { data -> InternalTransaction? in
                guard let hash = data["hash"].flatMap({ Data(hex: $0) }) else { return nil }
                guard let blockNumber = data["blockNumber"].flatMap({ Int($0) }) else { return nil }
                guard let from = data["from"].flatMap({ Data(hex: $0) }).map({ Address(raw: $0) }) else { return nil }
                guard let to = data["to"].flatMap({ Data(hex: $0) }).map({ Address(raw: $0) }) else { return nil }
                guard let value = data["value"].flatMap({ BigUInt($0) }) else { return nil }
                guard let traceId = data["traceId"] else { return nil }

                return InternalTransaction(
                        hash: hash,
                        blockNumber: blockNumber,
                        from: from,
                        to: to,
                        value: value,
                        traceId: traceId
                )
            }
        }
    }

    func internalTransactionsSingle(transactionHash: NotSyncedInternalTransaction) -> Single<[InternalTransaction]> {
        etherscanService.internalTransactionsSingle(transactionHash: transactionHash.hash).map { array -> [InternalTransaction] in
            array.compactMap { data -> InternalTransaction? in
                guard let blockNumber = data["blockNumber"].flatMap({ Int($0) }) else { return nil }
                guard let from = data["from"].flatMap({ Data(hex: $0) }).map({ Address(raw: $0) }) else { return nil }
                guard let to = data["to"].flatMap({ Data(hex: $0) }).map({ Address(raw: $0) }) else { return nil }
                guard let value = data["value"].flatMap({ BigUInt($0) }) else { return nil }

                return InternalTransaction(
                        hash: transactionHash.hash,
                        blockNumber: blockNumber,
                        from: from,
                        to: to,
                        value: value,
                        traceId: ""
                )
            }
        }
    }

}

extension EtherscanService {

    public enum RequestError: Error {
        case invalidStatus
        case responseError(message: String?, result: String?)
        case invalidResult
        case rateLimitExceeded
    }

}

extension EtherscanService: IApiMapper {

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
