import RxSwift

class ApiProvider {
    private let networkManager: NetworkManager
    private let network: INetwork

    private let infuraProjectId: String
    private let etherscanApiKey: String

    init(networkManager: NetworkManager, network: INetwork, infuraProjectId: String, etherscanApiKey: String) {
        self.networkManager = networkManager
        self.network = network
        self.infuraProjectId = infuraProjectId
        self.etherscanApiKey = etherscanApiKey
    }

}

extension ApiProvider {

    private var etherscanBaseUrl: String {
        switch network {
        case is Ropsten: return "https://ropsten.etherscan.io"
        case is Kovan: return "https://kovan.etherscan.io"
        default: return "https://api.etherscan.io"
        }
    }

    private func etherscanSingle<T>(params: [String: Any], mapper: @escaping (Any) -> T?) -> Single<T> {
        let urlString = "\(etherscanBaseUrl)/api"

        var parameters = params
        parameters["apikey"] = etherscanApiKey

        return networkManager.single(urlString: urlString, httpMethod: .get, parameters: parameters, mapper: mapper)
    }

    private func etherscanTransactionsSingle(params: [String: Any]) -> Single<[[String: String]]> {
        return etherscanSingle(params: params) { data -> [[String: String]]? in
            if let map = data as? [String: Any], let result = map["result"] as? [[String: String]] {
                return result
            }
            return nil
        }
    }

}

extension ApiProvider {

    private var infuraBaseUrl: String {
        switch network {
        case is Ropsten: return "https://ropsten.infura.io"
        case is Kovan: return "https://kovan.infura.io"
        default: return "https://mainnet.infura.io"
        }
    }

    private func infuraSingle<T>(method: String, params: [Any], mapper: @escaping (Any) -> T?) -> Single<T> {
        let urlString = "\(infuraBaseUrl)/v3/\(infuraProjectId)"

        let parameters: [String: Any] = [
            "jsonrpc": "2.0",
            "method": method,
            "params": params,
            "id": 1
        ]

        return networkManager.single(urlString: urlString, httpMethod: .post, parameters: parameters, mapper: mapper)
    }

    private func infuraVoidSingle(method: String, params: [Any]) -> Single<Void> {
        return infuraSingle(method: method, params: params) { data -> Void? in return () }
    }

    private func infuraIntSingle(method: String, params: [Any]) -> Single<Int> {
        return infuraSingle(method: method, params: params) { data -> Int? in
            if let map = data as? [String: Any], let result = map["result"] as? String, let int = Int(result.stripHexPrefix(), radix: 16) {
                return int
            }
            return nil
        }
    }

    private func infuraBIntSingle(method: String, params: [Any]) -> Single<BInt> {
        return infuraSingle(method: method, params: params) { data -> BInt? in
            if let map = data as? [String: Any], let result = map["result"] as? String, let bInt = BInt(result.stripHexPrefix(), radix: 16) {
                return bInt
            }
            return nil
        }
    }

}

extension ApiProvider: IApiProvider {

    func lastBlockHeightSingle() -> Single<Int> {
        return infuraIntSingle(method: "eth_blockNumber", params: [])
    }

    func transactionCountSingle(address: Data) -> Single<Int> {
        return infuraIntSingle(method: "eth_getTransactionCount", params: [address.toHexString(), "pending"])
    }

    func balanceSingle(address: Data) -> Single<BInt> {
        return infuraBIntSingle(method: "eth_getBalance", params: [address.toHexString(), "latest"])
    }

    func balanceErc20Single(address: Data, contractAddress: Data) -> Single<BInt> {
        let data = ERC20.ContractFunctions.balanceOf(address: address).data

        let callParams: [String: Any] = [
            "to": contractAddress.toHexString(),
            "data": data.toHexString()
        ]

        return infuraBIntSingle(method: "eth_call", params: [callParams, "latest"])
    }

    func transactionsSingle(address: Data, startBlock: Int) -> Single<[Transaction]> {
        let params: [String: Any] = [
            "module": "account",
            "action": "txlist",
            "address": address.toHexString(),
            "startblock": startBlock,
            "endblock": 99999999,
            "sort": "asc"
        ]

        return etherscanTransactionsSingle(params: params).map { array -> [Transaction] in
            return array.compactMap { data -> Transaction? in
                guard let hash = data["hash"].flatMap({ Data(hex: $0) }) else { return nil }
                guard let nonce = data["nonce"].flatMap({ Int($0) }) else { return nil }
                guard let from = data["from"].flatMap({ Data(hex: $0) }) else { return nil }
                guard let to = data["to"].flatMap({ Data(hex: $0) }) else { return nil }
                guard let value = data["value"].flatMap({ BInt($0) }) else { return nil }
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

    func transactionsErc20Single(address: Data, startBlock: Int) -> Single<[Transaction]> {
        return Single.just([])
//        let params: [String: Any] = [
//            "module": "account",
//            "action": "tokentx",
//            "address": address.toHexString(),
//            "startblock": startBlock,
//            "endblock": 99999999,
//            "sort": "asc"
//        ]
//
//        return etherscanTransactionsSingle(params: params).map { array -> [Transaction] in
//            return []
//        }
    }

    func sendSingle(signedTransaction: Data) -> Single<Void> {
        return infuraVoidSingle(method: "eth_sendRawTransaction", params: [signedTransaction.toHexString()])
    }

}
