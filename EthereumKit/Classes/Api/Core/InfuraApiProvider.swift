import RxSwift
import BigInt
import Alamofire

class InfuraApiProvider {
    private let networkManager: NetworkManager
    private let network: INetwork

    private let id: String
    private var secret: String?
    private let address: Data

    init(networkManager: NetworkManager, network: INetwork, id: String, secret: String?, address: Data) {
        self.networkManager = networkManager
        self.network = network
        self.id = id
        self.secret = secret
        self.address = address
    }

}

extension InfuraApiProvider {

    private var infuraBaseUrl: String {
        switch network {
        case is Ropsten: return "https://ropsten.infura.io"
        case is Kovan: return "https://kovan.infura.io"
        default: return "https://mainnet.infura.io"
        }
    }

    private func infuraSingle<T>(method: String, params: [Any], mapper: @escaping (Any) -> T?) -> Single<T> {
        let urlString = "\(infuraBaseUrl)/v3/\(id)"

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

        let request = networkManager.session.request(urlString, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)

        return networkManager.singleOld(request: request, mapper: mapper)
    }

    private static func parseInfuraError(data: [String: Any]) -> Error {
        if let error = data["error"] as? [String: Any] {
            let message = (error["message"] as? String) ?? ""
            let code = (error["message"] as? Int) ?? -1

            return ApiError.infuraError(code: code, message: message)
        }
        return ApiError.invalidData
    }

    private func infuraVoidSingle(method: String, params: [Any]) -> Single<Void> {
        infuraSingle(method: method, params: params) { data -> [String: Any]? in
            data as? [String: Any]
        }.flatMap { data -> Single<Void> in
            guard data["result"] != nil else {
                return Single.error(InfuraApiProvider.parseInfuraError(data: data))
            }

            return Single.just(())
        }
    }

    private func infuraIntSingle(method: String, params: [Any]) -> Single<Int> {
        infuraSingle(method: method, params: params) { data -> Int? in
            if let map = data as? [String: Any], let result = map["result"] as? String, let int = Int(result.stripHexPrefix(), radix: 16) {
                return int
            }
            return nil
        }
    }

    private func infuraBigIntSingle(method: String, params: [Any]) -> Single<BigUInt> {
        infuraSingle(method: method, params: params) { data -> BigUInt? in
            if let map = data as? [String: Any], let result = map["result"] as? String, let bigInt = BigUInt(result.stripHexPrefix(), radix: 16) {
                return bigInt
            }
            return nil
        }
    }

    private func infuraStringSingle(method: String, params: [Any]) -> Single<String> {
        infuraSingle(method: method, params: params) { data -> String? in
            if let map = data as? [String: Any], let result = map["result"] as? String {
                return result
            }
            return nil
        }
    }

}

extension InfuraApiProvider: IRpcApiProvider {

    var source: String {
        "infura.io"
    }

    func lastBlockHeightSingle() -> Single<Int> {
        infuraIntSingle(method: "eth_blockNumber", params: [])
    }

    func transactionCountSingle() -> Single<Int> {
        infuraIntSingle(method: "eth_getTransactionCount", params: [address.toHexString(), "pending"])
    }

    func balanceSingle() -> Single<BigUInt> {
        infuraBigIntSingle(method: "eth_getBalance", params: [address.toHexString(), "latest"])
    }

    func sendSingle(signedTransaction: Data) -> Single<Void> {
        infuraVoidSingle(method: "eth_sendRawTransaction", params: [signedTransaction.toHexString()])
    }

    func getLogs(address: Data?, fromBlock: Int, toBlock: Int, topics: [Any?]) -> Single<[EthereumLog]> {
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
            "address": address?.toHexString() as Any,
            "topics": jsonTopics
        ]

        return infuraSingle(method: "eth_getLogs", params: [params]) {data -> [EthereumLog] in
            if let map = data as? [String: Any], let result = map["result"] as? [Any] {
                return result.compactMap { EthereumLog(json: $0) }
            }
            return []
        }
    }

    func transactionReceiptStatusSingle(transactionHash: Data) -> Single<TransactionStatus> {
        infuraSingle(method: "eth_getTransactionReceipt", params: [transactionHash.toHexString()]) { data -> TransactionStatus in
            guard let map = data as? [String: Any],
                  let log = map["result"] as? [String: Any],
                  let statusString = log["status"] as? String,
                  let success = Int(statusString.stripHexPrefix(), radix: 16) else {
                return .notFound
            }
            return success == 0 ? .failed : .success
        }
    }

    func transactionExistSingle(transactionHash: Data) -> Single<Bool> {
        infuraSingle(method: "eth_getTransactionByHash", params: [transactionHash.toHexString()]) {data -> Bool in
            guard let map = data as? [String: Any], let _ = map["result"] as? [String: Any] else {
                return false
            }
            return true
        }
    }

    func getStorageAt(contractAddress: String, position: String, blockNumber: Int?) -> Single<String> {
        infuraStringSingle(method: "eth_getStorageAt", params: [contractAddress, position, "latest"])
    }

    func call(contractAddress: String, data: String, blockNumber: Int?) -> Single<String> {
        infuraStringSingle(method: "eth_call", params: [["to": contractAddress, "data": data], "latest"])
    }

    func getEstimateGas(from: String?, contractAddress: String, amount: BigUInt?, gasLimit: Int?, gasPrice: Int?, data: String?) -> Single<String> {
        var params = [String: Any]()
        if let from = from {
            params["from"] = from.lowercased()
        }
        if let amount = amount {
            params["value"] = "0x" + amount.serialize().toRawHexString().removeLeadingZeros()
        }
        if let gasLimit = gasLimit {
            params["gas"] = "0x" + String(gasLimit, radix: 16).removeLeadingZeros()
        }
        if let gasPrice = gasPrice {
            params["gas"] = "0x" + String(gasPrice, radix: 16).removeLeadingZeros()
        }
        params["to"] = contractAddress.lowercased()
        params["data"] = data

        return infuraSingle(method: "eth_estimateGas", params: [params]) { data -> [String: Any]? in
            data as? [String: Any]
        }.flatMap { data -> Single<String> in
            if let result = data["result"] as? String {
                return Single.just(result)
            } else {
                return Single.error(InfuraApiProvider.parseInfuraError(data: data))
            }
        }
   }

    func getBlock(byNumber number: Int) -> Single<Block> {
        infuraSingle(method: "eth_getBlockByNumber", params: ["0x" + String(number, radix: 16), false]) {data -> Block? in
            if let map = data as? [String: Any], let result = map["result"] {
                return Block(json: result)
            }
            return nil
        }
    }

}
