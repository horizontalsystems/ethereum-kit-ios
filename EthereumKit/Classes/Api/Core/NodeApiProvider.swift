import RxSwift
import BigInt
import Alamofire
import HsToolKit

class NodeApiProvider {
    private let networkManager: NetworkManager
    private let url: URL
    let blockTime: TimeInterval

    private let headers: HTTPHeaders
    private var currentRpcId = 0

    init(networkManager: NetworkManager, url: URL, blockTime: TimeInterval, auth: String?) {
        self.networkManager = networkManager
        self.url = url
        self.blockTime = blockTime

        var headers = HTTPHeaders()

        if let auth = auth {
            headers.add(.authorization(username: "", password: auth))
        }

        self.headers = headers
    }

    private func rpcResultSingle(parameters: [String: Any]) -> Single<Any> {
        networkManager.single(
                url: url,
                method: .post,
                parameters: parameters,
                mapper: self,
                encoding: JSONEncoding.default,
                headers: headers,
                interceptor: self,
                responseCacherBehavior: .doNotCache
        )
    }

}

extension NodeApiProvider {

    public enum RequestError: Error {
        case invalidResponse(jsonObject: Any)
    }

}

extension NodeApiProvider: RequestInterceptor {

    public func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> ()) {
        let error = NetworkManager.unwrap(error: error)

        if case let JsonRpcResponse.ResponseError.rpcError(rpcError) = error, rpcError.code == -32005 {
            var backoffSeconds = 1.0

            if let errorData = rpcError.data as? [String: Any], let timeInterval = errorData["backoff_seconds"] as? TimeInterval {
                backoffSeconds = timeInterval
            }

            completion(.retryWithDelay(backoffSeconds))
        } else {
            completion(.doNotRetry)
        }
    }

}

extension NodeApiProvider: IApiMapper {

    func map(statusCode: Int, data: Any?) throws -> Any {
        guard let response = data else {
            throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
        }

        return response
    }

}

extension NodeApiProvider: IRpcApiProvider {

    var source: String {
        url.host ?? ""
    }

    func single<T>(rpc: JsonRpc<T>) -> Single<T> {
        currentRpcId += 1

        return rpcResultSingle(parameters: rpc.parameters(id: currentRpcId))
                .flatMap { jsonObject in
                    do {
                        guard let rpcResponse = JsonRpcResponse.response(jsonObject: jsonObject) else {
                            throw RequestError.invalidResponse(jsonObject: jsonObject)
                        }

                        return Single.just(try rpc.parse(response: rpcResponse))
                    } catch {
                        return Single.error(error)
                    }
                }
    }

}
