import RxSwift
import BigInt
import HsToolKit

public class IncubedRpcApiProvider {
    private let GET_LOGS_REQUEST_MAX_BLOCKS_RANGE = 10000 // max blocks range for which eth_getLogs can be queried with no-proof, this limit is set by in3-c server
    private let serialQueueScheduler = SerialDispatchQueueScheduler(qos: .utility)
    private var disposeBag = DisposeBag()

    private let network: INetwork
    private let logger: Logger?

    private let in3: In3Private

    init(logger: Logger? = nil) {
        self.network = NetworkType.mainNet.network
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

    private func lastBlockHeightSingle() -> Single<Int> {
        Single.fromIncubed {
            self.logger?.log(level: .debug, message: "IncubedRpcApiProvider: getLastBlockHeight")
            let height = try self.sendRpc(method: BLOCK_NUMBER, parameters: [])

            guard let intValue: Int = RpcParamsHelper.convert(height) else {
                throw IncubedError.wrongParsingResult
            }
            return intValue
        }.subscribeOn(serialQueueScheduler)
    }

    private func transactionCountSingle(address: Address) -> Single<Int> {
        Single.fromIncubed {
            self.logger?.log(level: .debug, message: "IncubedRpcApiProvider: transactionCountSingle \(address)")
            let count = self.in3.transactionCount(address.raw)

            return Int(count)
        }.subscribeOn(serialQueueScheduler)
    }

    private func balanceSingle(address: Address) -> Single<BigUInt> {
        Single.fromIncubed {
            self.logger?.log(level: .debug, message: "IncubedRpcApiProvider: balanceSingle \(address)")

            let balance = try self.sendRpc(method: GET_BALANCE, parameters: [address.raw, "latest"])
            guard let bigInt: BigUInt = RpcParamsHelper.convert(balance) else {
                throw IncubedError.wrongParsingResult
            }
            return bigInt
        }.subscribeOn(serialQueueScheduler)
    }

    private func sendSingle(signedTransaction: Data) -> Single<Data> {
        let stringSingle: Single<String> = Single.fromIncubed {
            self.logger?.log(level: .debug, message: "IncubedRpcApiProvider: sendSingle \(signedTransaction.toHexString())")

            return try self.sendRpc(method: SEND_RAW_TRANSACTION, parameters: [signedTransaction])
        }.subscribeOn(serialQueueScheduler)

        return stringSingle.flatMap { value -> Single<Data> in
            guard let data = Data(hex: value) else {
                return Single.error(IncubedError.invalidData)
            }

            return Single.just(data)
        }
    }

    private func getLogs(address: Address?, fromBlock: Int, toBlock: Int, topics: [Any?]) -> Single<[EthereumLog]> {
        Single.fromIncubed {
            self.logger?.log(level: .debug, message: "IncubedRpcApiProvider: getLogs \(address?.hex ?? "Nil") \(fromBlock) - \(toBlock)")

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

    private func getLogsBlocking(address: Address?, fromBlock: Int, toBlock: Int, topics: [Any?]) throws -> String {
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
            "address": address?.hex as Any,
            "topics": jsonTopics
        ]
        return try sendRpc(method: GET_LOGS, parameters: [params])
    }

    private func transactionReceiptStatusSingle(transactionHash: Data) -> Single<TransactionStatus> {
        Single.fromIncubed {
            self.logger?.log(level: .debug, message: "IncubedRpcApiProvider: transactionReceiptStatusSingle \(transactionHash.toHexString())")

            let success = self.in3.transactionReceipt(transactionHash)
            return success ? TransactionStatus.success : TransactionStatus.failed
        }.subscribeOn(serialQueueScheduler)
    }

    private func transactionExistSingle(transactionHash: Data) -> Single<Bool> {
        Single.fromIncubed {
            self.logger?.log(level: .debug, message: "IncubedRpcApiProvider: transactionExistSingle  \(transactionHash.toHexString())")

            return self.in3.transactionReceipt(transactionHash)
        }.subscribeOn(serialQueueScheduler)
    }

    private func getStorageAt(contractAddress: Address, positionData: Data, defaultBlockParameter: DefaultBlockParameter) -> Single<Data> {
        let stringSingle: Single<String> = Single.fromIncubed {
            self.logger?.log(level: .debug, message: "IncubedRpcApiProvider: getStorageAt \(contractAddress) \(positionData.toHexString()) \(defaultBlockParameter)")

            return try self.sendRpc(method: GET_STORAGE_AT, parameters: [contractAddress.hex, positionData.toHexString(), defaultBlockParameter.raw])
        }.subscribeOn(serialQueueScheduler)

        return stringSingle.flatMap { value -> Single<Data> in
            guard let data = Data(hex: value) else {
                return Single.error(IncubedError.invalidData)
            }

            return Single.just(data)
        }
    }

    private func call(contractAddress: Address, data: Data, defaultBlockParameter: DefaultBlockParameter) -> Single<Data> {
        let stringSingle: Single<String> = Single.fromIncubed {
            self.logger?.log(level: .debug, message: "IncubedRpcApiProvider: call \(contractAddress) \(data.toHexString()) \(defaultBlockParameter)")

            let callParams: [String: Any] = [
                "to": contractAddress.hex,
                "data": data.toHexString(),
            ]
            return try self.sendRpc(method: CALL, parameters: [callParams, defaultBlockParameter.raw])
        }.subscribeOn(serialQueueScheduler)

        return stringSingle.flatMap { value -> Single<Data> in
            guard let data = Data(hex: value) else {
                return Single.error(IncubedError.invalidData)
            }

            return Single.just(data)
        }
    }

    private func getEstimateGas(from: Address, to: Address, amount: BigUInt?, gasLimit: Int?, gasPrice: Int?, data: Data?) -> Single<Int> {
        let from = from.hex
        let to = to.hex
        let data = data?.toHexString()

        let stringSingle: Single<String> = Single.fromIncubed {
                    self.logger?.log(level: .debug, message: "IncubedRpcApiProvider: getEstimateGas \(from) \(to) \(amount?.description ?? "Nil") \(data ?? "Nil")")
                    let callParams: [String: Any] = [
                        "to": to,
                        "from": from,
                        "gas": gasLimit as Any,
                        "gasPrice": gasPrice as Any,
                        "value": amount as Any,
                        "data": data as Any
                    ]
                    return try self.sendRpc(method: ESTIMATE_GAS, parameters: [callParams, "latest"])
                } .subscribeOn(serialQueueScheduler)

        return stringSingle.flatMap { (value: String) -> Single<Int> in
            guard let data = Int(value.stripHexPrefix(), radix: 16) else {
                return Single.error(IncubedError.invalidData)
            }

            return Single.just(data)
        }
    }

    private func getBlock(byNumber number: Int) -> Single<Block> {
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

extension IncubedRpcApiProvider {

    public enum IncubedError: Error {
        case wrongParsingResult
        case notReachable
        case invalidData
    }

}

extension IncubedRpcApiProvider: IRpcApiProvider {

    var source: String {
        "Incubed"
    }

    func single<T>(rpc: JsonRpc<T>) -> Single<T> {
        switch rpc {
        case is BlockNumberJsonRpc:
            return lastBlockHeightSingle().map { $0 as! T }
        case let rpc as GetTransactionCountJsonRpc:
            return transactionCountSingle(address: rpc.address).map { $0 as! T }
        case let rpc as GetBalanceJsonRpc:
            return balanceSingle(address: rpc.address).map { $0 as! T }
        case let rpc as SendRawTransactionJsonRpc:
            return sendSingle(signedTransaction: rpc.signedTransaction).map { $0 as! T }
        case let rpc as GetLogsJsonRpc:
            return getLogs(address: rpc.address, fromBlock: rpc.fromBlock, toBlock: rpc.toBlock, topics: rpc.topics).map { $0 as! T }
//        case let rpc as GetTransactionReceiptJsonRpc:
//            fatalError()
//        case let rpc as GetTransactionByHashJsonRpc:
//            fatalError()
        case let rpc as GetStorageAtJsonRpc:
            return getStorageAt(contractAddress: rpc.contractAddress, positionData: rpc.positionData, defaultBlockParameter: rpc.defaultBlockParameter).map { $0 as! T }
        case let rpc as CallJsonRpc:
            return call(contractAddress: rpc.contractAddress, data: rpc.data, defaultBlockParameter: rpc.defaultBlockParameter).map { $0 as! T }
        case let rpc as EstimateGasJsonRpc:
            return getEstimateGas(from: rpc.from, to: rpc.to, amount: rpc.amount, gasLimit: rpc.gasLimit, gasPrice: rpc.gasPrice, data: rpc.data).map { $0 as! T }
        case let rpc as GetBlockByNumberJsonRpc:
            return getBlock(byNumber: rpc.number).map { $0 as! T }
        default:
            fatalError("RPC is not supported by Incubed")
        }
    }

}
