import RxSwift
import BigInt
import HsToolKit

//public class IncubedRpcApiProvider {
//    private let GET_LOGS_REQUEST_MAX_BLOCKS_RANGE = 10000 // max blocks range for which eth_getLogs can be queried with no-proof, this limit is set by in3-c server
//    private let serialQueueScheduler = SerialDispatchQueueScheduler(qos: .utility)
//    private var disposeBag = DisposeBag()
//
//    private let logger: Logger?
//
//    private let in3: In3Private
//
//    init(logger: Logger? = nil) {
//        self.logger = logger
//
//        in3 = In3Private(chainId: 1)
//    }
//
//}
//
//extension IncubedRpcApiProvider {
//
//    private func sendRpc(method: String, parameters: [Any]) throws -> String {
//        var error: NSError?
//
//        let requestParams = RpcParamsHelper.convert(parameters).json ?? "[]"
//        let result = in3.rpcCall(method, params: requestParams, didFailWithError: &error)
//
//        if let error = error {
//            logger?.log(level: .debug, message: "IncubedRpcApiProvider: sendRpc ERROR: \(error)")
//            throw error
//        }
//        logger?.log(level: .debug, message: "IncubedRpcApiProvider: sendRpc Result: \(result)")
//        return RpcParamsHelper.dropQuotes(text: result)
//    }
//
//}
//
//extension IncubedRpcApiProvider {
//
//    public enum IncubedError: Error {
//        case wrongParsingResult
//        case notReachable
//        case invalidData
//    }
//
//}

//extension IncubedRpcApiProvider: IRpcApiProvider {
//
//    var source: String {
//        "Incubed"
//    }
//
//    func single<T>(rpc: JsonRpc<T>) -> Single<T> {
//        guard let method = (rpc.parameters()["method"] as? String),
//              let params = (rpc.parameters()["params"] as? [Any]) else {
//            return Single.error(IncubedError.invalidData)
//        }
//
//       return Single<String>.fromIncubed {
//            self.logger?.log(level: .debug, message: "IncubedRpcApiProvider: call \(method)")
//
//            return try self.sendRpc(method: method, parameters: params)
//        }.flatMap { result in
//            do {
//                return Single.just(try rpc.parse(result: result))
//            } catch {
//                return Single.error(error)
//            }
//        }.subscribeOn(serialQueueScheduler)
//    }
//
//}
