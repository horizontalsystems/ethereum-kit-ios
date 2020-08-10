import RxSwift
import BigInt
import Alamofire
import HsToolKit

class InfuraApiProvider {
    private let networkManager: NetworkManager
    private let network: INetwork

    private let id: String
    private var secret: String?
    private let address: Address

    init(networkManager: NetworkManager, network: INetwork, id: String, secret: String?, address: Address) {
        self.networkManager = networkManager
        self.network = network
        self.id = id
        self.secret = secret
        self.address = address
    }

    private var baseUrl: String {
        switch network {
        case is Ropsten: return "https://ropsten.infura.io"
        case is Kovan: return "https://kovan.infura.io"
        default: return "https://mainnet.infura.io"
        }
    }

    private func apiSingle(method: String, params: [Any]) -> Single<Any> {
        let urlString = "\(baseUrl)/v3/\(id)"

        let parameters: [String: Any] = [
            "jsonrpc": "2.0",
            "method": method,
            "params": params,
            "id": 1
        ]

        var headers = HTTPHeaders()

        if let secret = secret {
            headers.add(.authorization(username: "", password: secret))
        }

        let request = networkManager.session
                .request(urlString, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers, interceptor: self)
                .cacheResponse(using: ResponseCacher(behavior: .doNotCache))

        return networkManager.single(request: request, mapper: self)
    }

    private func apiSingle<T>(method: String, params: [Any], converter: @escaping (String) -> T?) -> Single<T> {
        apiSingle(method: method, params: params).flatMap { anyResult -> Single<T> in
            if let result = anyResult as? String, let converted = converter(result) {
                return Single.just(converted)
            }

            return Single.error(RequestError.invalidResult)
        }
    }

    private func voidSingle(method: String, params: [Any]) -> Single<Void> {
        apiSingle(method: method, params: params).map { _ in () }
    }

    private func stringSingle(method: String, params: [Any]) -> Single<String> {
        apiSingle(method: method, params: params) { string -> String? in string }
    }

    private func intSingle(method: String, params: [Any]) -> Single<Int> {
        apiSingle(method: method, params: params) { string -> Int? in Int(string.stripHexPrefix(), radix: 16) }
    }

    private func bigIntSingle(method: String, params: [Any]) -> Single<BigUInt> {
        apiSingle(method: method, params: params) { string -> BigUInt? in BigUInt(string.stripHexPrefix(), radix: 16) }
    }

    private func dataSingle(method: String, params: [Any]) -> Single<Data> {
        apiSingle(method: method, params: params) { string -> Data? in Data(hex: string) }
    }

}

extension InfuraApiProvider {

    public enum RequestError: Error {
        case invalidResult
        case rateLimitExceeded(backoffSeconds: TimeInterval)
        case responseError(code: Int, message: String)
    }

}

extension InfuraApiProvider: RequestInterceptor {

    public func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> ()) {
        let error = NetworkManager.unwrap(error: error)

        if case let RequestError.rateLimitExceeded(backoffSeconds) = error {
            completion(.retryWithDelay(backoffSeconds))
        } else {
            completion(.doNotRetry)
        }
    }

}

extension InfuraApiProvider: IApiMapper {

    func map(statusCode: Int, data: Any?) throws -> Any {
        guard let map = data as? [String: Any] else {
            throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
        }

        if let error = map["error"] as? [String: Any] {
            let message = (error["message"] as? String) ?? ""
            let code = (error["message"] as? Int) ?? -1

            if code == -32005 {
                var backoffSeconds = 1.0

                if let errorData = error["data"] as? [String: Any], let timeInterval = errorData["backoff_seconds"] as? TimeInterval {
                    backoffSeconds = timeInterval
                }

                throw RequestError.rateLimitExceeded(backoffSeconds: backoffSeconds)
            }

            throw RequestError.responseError(code: code, message: message)
        }

        guard let result = map["result"] else {
            throw RequestError.invalidResult
        }

        return result
    }

}

extension InfuraApiProvider: IRpcApiProvider {

    var source: String {
        "infura.io"
    }

    func lastBlockHeightSingle() -> Single<Int> {
        intSingle(method: "eth_blockNumber", params: [])
    }

    func transactionCountSingle() -> Single<Int> {
        intSingle(method: "eth_getTransactionCount", params: [address.hex, "pending"])
    }

    func balanceSingle() -> Single<BigUInt> {
        Single.zip([
                bigIntSingle(method: "eth_getBalance", params: [address.hex, "latest"])
        ]).map { array -> BigUInt in array[0] }
    }

    func sendSingle(signedTransaction: Data) -> Single<Void> {
        voidSingle(method: "eth_sendRawTransaction", params: [signedTransaction.toHexString()])
    }

    func getLogs(address: Address?, fromBlock: Int, toBlock: Int, topics: [Any?]) -> Single<[EthereumLog]> {
        let toBlockStr = "0x" + String(toBlock, radix: 16)
        let fromBlockStr = "0x" + String(fromBlock, radix: 16)

        let jsonTopics: [Any?] = topics.map {
            if let array = $0 as? [Data?] {
                return array.map { topic -> String? in
                    topic?.toHexString()
                }
            } else if let data = $0 as? Data {
                return data.toHexString()
            } else {
                return nil
            }
        }

        let params: [String: Any] = [
            "fromBlock": fromBlockStr,
            "toBlock": toBlockStr,
            "address": address?.hex as Any,
            "topics": jsonTopics
        ]

        return apiSingle(method: "eth_getLogs", params: [params]).flatMap { anyResult -> Single<[EthereumLog]> in
            if let result = anyResult as? [Any] {
                return Single.just(result.compactMap { EthereumLog(json: $0) })
            }
            return Single.just([])
        }
    }

    func transactionReceiptStatusSingle(transactionHash: Data) -> Single<TransactionStatus> {
        apiSingle(method: "eth_getTransactionReceipt", params: [transactionHash.toHexString()]).flatMap { anyResult -> Single<TransactionStatus> in
            guard let resultMap = anyResult as? [String: Any], let statusString = resultMap["status"] as? String,
                  let success = Int(statusString.stripHexPrefix(), radix: 16) else {
                return Single.just(.notFound)
            }
            return Single.just(success == 0 ? .failed : .success)
        }
    }

    func transactionExistSingle(transactionHash: Data) -> Single<Bool> {
        apiSingle(method: "eth_getTransactionByHash", params: [transactionHash.toHexString()]).flatMap { anyResult -> Single<Bool> in
            guard let _ = anyResult as? [String: Any] else {
                return Single.just(false)
            }
            return Single.just(true)
        }
    }

    func getStorageAt(contractAddress: Address, position: String, defaultBlockParameter: DefaultBlockParameter) -> Single<Data> {
        dataSingle(method: "eth_getStorageAt", params: [contractAddress.hex, position, defaultBlockParameter.raw])
    }

    func call(contractAddress: Address, data: String, defaultBlockParameter: DefaultBlockParameter) -> Single<Data> {
        dataSingle(method: "eth_call", params: [["to": contractAddress.hex, "data": data], defaultBlockParameter.raw])
    }

    func getEstimateGas(to: Address, amount: BigUInt?, gasLimit: Int?, gasPrice: Int?, data: Data?) -> Single<Int> {
        var params: [String: Any] = [
            "from": address.hex,
            "to": to.hex
        ]

        if let amount = amount {
            params["value"] = "0x" + amount.serialize().hex.removeLeadingZeros()
        }
        if let gasLimit = gasLimit {
            params["gas"] = "0x" + String(gasLimit, radix: 16).removeLeadingZeros()
        }
        if let gasPrice = gasPrice {
            params["gasPrice"] = "0x" + String(gasPrice, radix: 16).removeLeadingZeros()
        }
        if let data = data {
            params["data"] = data.toHexString()
        }

        return intSingle(method: "eth_estimateGas", params: [params])
    }

    func getBlock(byNumber number: Int) -> Single<Block> {
        apiSingle(method: "eth_getBlockByNumber", params: ["0x" + String(number, radix: 16), false]).flatMap { anyResult -> Single<Block> in
            if let block = Block(json: anyResult) {
                return Single.just(block)
            }

            return Single.error(RequestError.invalidResult)
        }
    }

}
