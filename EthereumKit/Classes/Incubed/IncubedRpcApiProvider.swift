import RxSwift
import BigInt

class IncubedRpcApiProvider {
    private let GET_LOGS_REQUEST_MAX_BLOCKS_RANGE = 10000 // max blocks range for which eth_getLogs can be queried with no-proof, this limit is set by in3-c server
    private let serialQueueScheduler = SerialDispatchQueueScheduler(qos: .utility)
    private var disposeBag = DisposeBag()

    private let network: INetwork
    private let address: Data
    private let logger: Logger?

    private let in3: In3Private

    public init(address: Data, logger: Logger? = nil) {

        self.network = NetworkType.mainNet.network
        self.address = address
        self.logger = logger

        in3 = In3Private(chainId: 1)
    }

}

extension IncubedRpcApiProvider {

    private func sendRpc(method: String, parameters: [Any]) throws -> String {
        var error: NSError?
        let result = in3.rpcCall(method, params: RpcParamsHelper.convert(parameters).json ?? "[]", didFailWithError: &error)
        if let error = error {
            logger?.log(level: .debug, message: "IncubedRpcApiProvider: sendRpc ERROR: \(error)")
            throw error
        }
        logger?.log(level: .debug, message: "IncubedRpcApiProvider: sendRpc Result: \(result)")
        return RpcParamsHelper.dropQuotes(text: result)
    }

}

public enum IncubedError: Error {
    case wrongParsingResult
    case notReachable
}

extension IncubedRpcApiProvider: IRpcApiProvider {

    var source: String {
        "Incubed"
    }

    func lastBlockHeightSingle() -> Single<Int> {
        Single.fromIncubed {
            self.logger?.log(level: .debug, message: "IncubedRpcApiProvider: getLastBlockHeight")
            let height = try self.sendRpc(method: BLOCK_NUMBER, parameters: [])

            guard let intValue: Int = RpcParamsHelper.convert(height) else {
                throw IncubedError.wrongParsingResult
            }
            return intValue
        }.subscribeOn(serialQueueScheduler)
    }

    func transactionCountSingle() -> Single<Int> {
        Single.fromIncubed {
            self.logger?.log(level: .debug, message: "IncubedRpcApiProvider: transactionCountSingle \(self.address.toHexString())")
            let count = self.in3.transactionCount(self.address)

            return Int(count)
        }.subscribeOn(serialQueueScheduler)
    }

    func balanceSingle() -> Single<BigUInt> {
        Single.fromIncubed {
            self.logger?.log(level: .debug, message: "IncubedRpcApiProvider: balanceSingle \(self.address.toHexString())")

            let balance = try self.sendRpc(method: GET_BALANCE, parameters: [self.address, "latest"])
            guard let bigInt: BigUInt = RpcParamsHelper.convert(balance) else {
                throw IncubedError.wrongParsingResult
            }
            return bigInt
        }.subscribeOn(serialQueueScheduler)
    }

    func sendSingle(signedTransaction: Data) -> Single<Void> {
        Single.fromIncubed {
            self.logger?.log(level: .debug, message: "IncubedRpcApiProvider: sendSingle \(signedTransaction.toHexString())")

            _ = try self.sendRpc(method: SEND_RAW_TRANSACTION, parameters: [signedTransaction])
        }.subscribeOn(serialQueueScheduler)
    }

    func getLogs(address: Data?, fromBlock: Int, toBlock: Int, topics: [Any?]) -> Single<[EthereumLog]> {
        Single.fromIncubed {
            self.logger?.log(level: .debug, message: "IncubedRpcApiProvider: getLogs \(address?.toHexString() ?? "Nil") \(fromBlock) - \(toBlock)")

            var requestFrom = fromBlock
            var logs = [EthereumLog]()
            while (requestFrom < toBlock) {
                let requestTo: Int
                if (requestFrom + self.GET_LOGS_REQUEST_MAX_BLOCKS_RANGE > toBlock) {
                    requestTo = toBlock
                } else {
                    requestTo = requestFrom + self.GET_LOGS_REQUEST_MAX_BLOCKS_RANGE
                }
                let partialLogs = try self.getLogsBlocking(address: address, fromBlock: requestFrom, toBlock: requestTo, topics: topics)
                //TODO make GetLogs
                print(partialLogs)
                logs.append(contentsOf: [])

                requestFrom = requestTo + 1
            }

            return logs
        }.subscribeOn(serialQueueScheduler)
    }

    func getLogsBlocking(address: Data?, fromBlock: Int, toBlock: Int, topics: [Any?]) throws -> String {
        logger?.log(level: .debug, message: "IncubedRpcApiProvider: getLogsBlocked \(fromBlock) - \(toBlock)")

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
            "fromBlock": toBlock,
            "toBlock": fromBlock,
            "address": address?.toHexString() as Any,
            "topics": jsonTopics
        ]
        return try sendRpc(method: GET_LOGS, parameters: [params])
    }

    func transactionReceiptStatusSingle(transactionHash: Data) -> Single<TransactionStatus> {
        Single.fromIncubed {
            self.logger?.log(level: .debug, message: "IncubedRpcApiProvider: transactionReceiptStatusSingle \(transactionHash.toHexString())")

            let success = self.in3.transactionReceipt(transactionHash)
            return success ? TransactionStatus.success : TransactionStatus.failed
        }.subscribeOn(serialQueueScheduler)
    }

    func transactionExistSingle(transactionHash: Data) -> Single<Bool> {
        Single.fromIncubed {
            self.logger?.log(level: .debug, message: "IncubedRpcApiProvider: transactionExistSingle  \(transactionHash.toHexString())")

            return self.in3.transactionReceipt(transactionHash)
        }.subscribeOn(serialQueueScheduler)
    }

    func getStorageAt(contractAddress: String, position: String, blockNumber: Int?) -> Single<String> {
        Single.fromIncubed {
            self.logger?.log(level: .debug, message: "IncubedRpcApiProvider: getStorageAt \(contractAddress) \(position) \(blockNumber ?? -1)")

            return try self.sendRpc(method: GET_STORAGE_AT, parameters: [contractAddress, position, blockNumber ?? "latest"])
        }.subscribeOn(serialQueueScheduler)
    }

    func call(contractAddress: String, data: String, blockNumber: Int?) -> Single<String> {
        Single.fromIncubed {
            self.logger?.log(level: .debug, message: "IncubedRpcApiProvider: call \(contractAddress) \(data) \(blockNumber ?? -1)")

            let callParams: [String: Any] = [
                "to": contractAddress,
                "data": data,
            ]
            return try self.sendRpc(method: CALL, parameters: [callParams, blockNumber ?? "latest"])
        }.subscribeOn(serialQueueScheduler)
    }

    func getEstimateGas(from: String?, contractAddress: String, amount: BigUInt?, gasLimit: Int?, gasPrice: Int?, data: String?) -> Single<String> {
        Single.fromIncubed {
            self.logger?.log(level: .debug, message: "IncubedRpcApiProvider: getEstimateGas \(from ?? "Nil") \(contractAddress) \(amount?.description ?? "Nil") \(data ?? "Nil")")
            let callParams: [String: Any] = [
                "to": contractAddress.lowercased(),
                "from": from?.lowercased() as Any,
                "gas": gasLimit as Any,
                "gasPrice": gasPrice as Any,
                "value": amount as Any,
                "data": data as Any
            ]
            return try self.sendRpc(method: ESTIMATE_GAS, parameters: [callParams, "latest"])
        }.subscribeOn(serialQueueScheduler)
    }

    func getBlock(byNumber number: Int) -> Single<Block> {
        Single.fromIncubed {
            self.logger?.log(level: .debug, message: "IncubedRpcApiProvider: getBlock \(number)")

            let json = try self.sendRpc(method: GET_BLOCK_BY_NUMBER, parameters: [number, false])

            guard let dictionary: [String: Any] = try RpcParamsHelper.convert(json), let block = Block(json: dictionary) else {
                throw IncubedError.wrongParsingResult
            }
            return block
        }.subscribeOn(serialQueueScheduler)
    }

}
