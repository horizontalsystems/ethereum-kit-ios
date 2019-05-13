import RxSwift
import Alamofire

class NetworkManager {
    private var logger: Logger?

    init(logger: Logger? = nil) {
        self.logger = logger
    }

    private func single(forRequest request: URLRequestConvertible) -> Single<DataResponse<Any>> {
        let single = Single<DataResponse<Any>>.create { observer in
            let requestReference = Alamofire.request(request)
                    .validate()
                    .responseJSON(queue: DispatchQueue.global(qos: .background), completionHandler: { response in
                        observer(.success(response))
                    })

            return Disposables.create {
                requestReference.cancel()
            }
        }

        return single
                .do(onSuccess: { [weak self] dataResponse in
                    switch dataResponse.result {
                    case .success(let result):
                        self?.logger?.verbose("API IN: \(dataResponse.request?.url?.absoluteString ?? "")\n\(result)")
                    case .failure:
                        let data = dataResponse.data.flatMap {
                            try? JSONSerialization.jsonObject(with: $0, options: .allowFragments)
                        }

                        self?.logger?.error("API IN: \(dataResponse.response?.statusCode ?? 0): \(dataResponse.request?.url?.absoluteString ?? "")\n\(data.map { "\($0)" } ?? "nil")")
                    }
                })
    }

    private func single<T>(forRequest request: URLRequestConvertible, mapper: @escaping (Any) -> T?) -> Single<T> {
        return single(forRequest: request)
                .flatMap { dataResponse -> Single<T> in
                    switch dataResponse.result {
                    case .success(let result):
                        if let value = mapper(result) {
                            return Single.just(value)
                        } else {
                            return Single.error(EthereumKit.NetworkError.mappingError)
                        }
                    case .failure:
                        if let response = dataResponse.response {
                            let data = dataResponse.data.flatMap { try? JSONSerialization.jsonObject(with: $0, options: .allowFragments) }
                            return Single.error(EthereumKit.NetworkError.serverError(status: response.statusCode, data: data))
                        } else {
                            return Single.error(EthereumKit.NetworkError.noConnection)
                        }
                    }
                }
    }

}

extension NetworkManager {

    func single<T>(urlString: String, httpMethod: HTTPMethod, basicAuth: (user: String, password: String)? = nil, parameters: [String: Any], mapper: @escaping (Any) -> T?) -> Single<T> {
        guard let url = URL(string: urlString) else {
            return Single.error(EthereumKit.NetworkError.invalidUrl)
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = httpMethod.rawValue
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        if let basicAuth = basicAuth, let header = Alamofire.Request.authorizationHeader(user: basicAuth.user, password: basicAuth.password) {
            urlRequest.setValue(header.value, forHTTPHeaderField: header.key)
        }

        let request = Request(urlRequest: urlRequest, encoding: httpMethod == .get ? URLEncoding.default : JSONEncoding.default, parameters: parameters)

        return single(forRequest: request, mapper: mapper)
                .do(onSubscribe: { [weak self] in
                    self?.logger?.verbose("API OUT: \(httpMethod.rawValue): \(url.absoluteString)\n\(parameters as AnyObject)")
                })
    }

}

extension NetworkManager {

    class Request: URLRequestConvertible {
        private let urlRequest: URLRequest
        private let encoding: ParameterEncoding
        private let parameters: [String: Any]?

        init(urlRequest: URLRequest, encoding: ParameterEncoding, parameters: [String: Any]?) {
            self.urlRequest = urlRequest
            self.encoding = encoding
            self.parameters = parameters
        }

        func asURLRequest() throws -> URLRequest {
            return try encoding.encode(urlRequest, with: parameters)
        }

    }

}
