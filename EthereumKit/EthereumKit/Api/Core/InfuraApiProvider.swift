import RxSwift
import BigInt

class InfuraApiProvider {
    private let networkManager: NetworkManager
    private let network: INetwork

    private let credentials: (id: String, secret: String?)
    private let address: Data

    init(networkManager: NetworkManager, network: INetwork, credentials: (id: String, secret: String?), address: Data) {
        self.networkManager = networkManager
        self.network = network
        self.credentials = credentials
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
        let urlString = "\(infuraBaseUrl)/v3/\(credentials.id)"

        let basicAuth = credentials.secret.map { (user: "", password: $0) }

        let parameters: [String: Any] = [
            "jsonrpc": "2.0",
            "method": method,
            "params": params,
            "id": 1
        ]

        return networkManager.single(urlString: urlString, httpMethod: .post, basicAuth: basicAuth, parameters: parameters, mapper: mapper)
    }

    private func infuraVoidSingle(method: String, params: [Any]) -> Single<Void> {
        return infuraSingle(method: method, params: params) { data -> [String: Any]? in
            return data as? [String: Any]
        }.flatMap { data -> Single<Void> in
            guard data["result"] != nil else {
                return Single.error(EthereumKit.SendError.infuraError(message: (data["error"] as? [String: Any])?["message"] as? String ?? ""))
            }

            return Single.just(())
        }
    }

    private func infuraIntSingle(method: String, params: [Any]) -> Single<Int> {
        return infuraSingle(method: method, params: params) { data -> Int? in
            if let map = data as? [String: Any], let result = map["result"] as? String, let int = Int(result.stripHexPrefix(), radix: 16) {
                return int
            }
            return nil
        }
    }

    private func infuraBigIntSingle(method: String, params: [Any]) -> Single<BigUInt> {
        return infuraSingle(method: method, params: params) { data -> BigUInt? in
            if let map = data as? [String: Any], let result = map["result"] as? String, let bigInt = BigUInt(result.stripHexPrefix(), radix: 16) {
                return bigInt
            }
            return nil
        }
    }

    private func infuraStringSingle(method: String, params: [Any]) -> Single<String> {
        return infuraSingle(method: method, params: params) { data -> String? in
            if let map = data as? [String: Any], let result = map["result"] as? String {
                return result
            }
            return nil
        }
    }

}

extension InfuraApiProvider: IRpcApiProvider {

    func lastBlockHeightSingle() -> Single<Int> {
        return infuraIntSingle(method: "eth_blockNumber", params: [])
    }

    func transactionCountSingle() -> Single<Int> {
        return infuraIntSingle(method: "eth_getTransactionCount", params: [address.toHexString(), "pending"])
    }

    func balanceSingle() -> Single<BigUInt> {
        return infuraBigIntSingle(method: "eth_getBalance", params: [address.toHexString(), "latest"])
    }

    func sendSingle(signedTransaction: Data) -> Single<Void> {
        return infuraVoidSingle(method: "eth_sendRawTransaction", params: [signedTransaction.toHexString()])
    }

    func getLogs(address: Data?, fromBlock: Int?, toBlock: Int?, topics: [Any]) -> Single<[EthereumLog]> {
        var toBlockStr = "latest"
        if let toBlockInt = toBlock {
            toBlockStr = "0x" + String(toBlockInt, radix: 16)
        }
        var fromBlockStr = "latest"
        if let fromBlockInt = fromBlock {
            fromBlockStr = "0x" + String(fromBlockInt, radix: 16)
        }

        var jsonValueTopics = [Any?]()
        for topic in topics {
            if let data = topic as? Data {
                jsonValueTopics.append(data.toHexString())
            } else if let string = topic as? String {
                jsonValueTopics.append(string)
            } else {
                jsonValueTopics.append(nil)
            }
        }


        let params: [String: Any] = [
            "fromBlock": fromBlockStr,
            "toBlock": toBlockStr,
            "address": address?.toHexString() as Any,
            "topics": jsonValueTopics
        ]

        return infuraSingle(method: "eth_getLogs", params: [params]) {data -> [EthereumLog] in
            if let map = data as? [String: Any], let result = map["result"] as? [Any] {
                return result.compactMap { EthereumLog(json: $0) }
            }
            return []
        }
    }

    func getStorageAt(contractAddress: String, position: String, blockNumber: Int?) -> Single<String> {
        return infuraStringSingle(method: "eth_getStorageAt", params: [contractAddress, position, "latest"])
    }

    func call(contractAddress: String, data: String, blockNumber: Int?) -> Single<String> {
        return infuraStringSingle(method: "eth_call", params: [["to": contractAddress, "data": data], "latest"])
    }

    func getBlock(byNumber number: Int) -> Single<Block> {
        return infuraSingle(method: "eth_getBlockByNumber", params: ["0x" + String(number, radix: 16), false]) {data -> Block? in
            if let map = data as? [String: Any], let result = map["result"] {
                return Block(json: result)
            }
            return nil
        }
    }

}
