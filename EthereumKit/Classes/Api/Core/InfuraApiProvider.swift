import RxSwift
import BigInt
import Alamofire
import HsToolKit

class InfuraApiProvider {
    private let networkManager: NetworkManager

    private let urlString: String
    private let headers: HTTPHeaders

    init(networkManager: NetworkManager, domain: String, id: String, secret: String?) {
        self.networkManager = networkManager

        urlString = "https://\(domain)/v3/\(id)"

        var headers = HTTPHeaders()

        if let secret = secret {
            headers.add(.authorization(username: "", password: secret))
        }

        self.headers = headers
    }

    private func rpcResultSingle(parameters: [String: Any]) -> Single<Any> {
        let request = networkManager.session
                .request(urlString, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers, interceptor: self)
                .cacheResponse(using: ResponseCacher(behavior: .doNotCache))

        return networkManager.single(request: request, mapper: self)
    }

}

extension InfuraApiProvider {

    public enum RequestError: Error {
        case invalidResponse(jsonObject: Any)
    }

}

extension InfuraApiProvider: RequestInterceptor {

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

extension InfuraApiProvider: IApiMapper {

    func map(statusCode: Int, data: Any?) throws -> Any {
        guard let response = data else {
            throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
        }

        return response
    }

}

extension InfuraApiProvider: IRpcApiProvider {

    var source: String {
        "Infura"
    }

    func single<T>(rpc: JsonRpc<T>) -> Single<T> {
        rpcResultSingle(parameters: rpc.parameters())
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
