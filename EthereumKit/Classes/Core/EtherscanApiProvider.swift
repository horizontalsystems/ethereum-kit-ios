import RxSwift
import BigInt

public class EtherscanApiProvider {
    private let networkManager: NetworkManager
    private let network: INetwork

    private let etherscanApiKey: String
    private let address: Data

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

    private func apiSingle<T>(params: [String: Any], mapper: @escaping (Any) -> T?) -> Single<T> {
        let urlString = "\(baseUrl)/api"

        var parameters = params
        parameters["apikey"] = etherscanApiKey

        return networkManager.single(urlString: urlString, httpMethod: .get, parameters: parameters, mapper: mapper)
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

        return apiSingle(params: params) { data -> [[String: String]]? in
            if let map = data as? [String: Any], let result = map["result"] as? [[String: String]] {
                return result
            }
            return nil
        }
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

        return apiSingle(params: params) { data -> [[String: String]]? in
            if let map = data as? [String: Any], let result = map["result"] as? [[String: String]] {
                return result
            }
            return nil
        }
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
