import RxSwift
import Alamofire

class NetworkManager {
    let session: Session

    init(logger: Logger? = nil) {
        let networkLogger = NetworkLogger(logger: logger)
        session = Session(eventMonitors: [networkLogger])
    }

    func single<T>(request: DataRequest, mapper: @escaping (Any) throws -> T) -> Single<T> {
        Single<T>.create { observer in
            let requestReference = request
                    .validate()
                    .response(queue: DispatchQueue.global(qos: .background), responseSerializer: JsonMapperResponseSerializer<T>(mapper: mapper)) { response in
                        switch response.result {
                        case .success(let result):
                            observer(.success(result))
                        case .failure(let error):
                            observer(.error(error))
                        }
                    }

            return Disposables.create {
                requestReference.cancel()
            }
        }
    }

    private func singleOld(request: DataRequest) -> Single<AFDataResponse<Any>> {
        Single<AFDataResponse<Any>>.create { observer in
            let requestReference = request
                    .validate()
                    .responseJSON(queue: DispatchQueue.global(qos: .background), completionHandler: { response in
                        observer(.success(response))
                    })

            return Disposables.create {
                requestReference.cancel()
            }
        }
    }

    func singleOld<T>(request: DataRequest, mapper: @escaping (Any) -> T?) -> Single<T> {
        singleOld(request: request)
                .flatMap { dataResponse -> Single<T> in
                    switch dataResponse.result {
                    case .success(let result):
                        if let value = mapper(result) {
                            return Single.just(value)
                        } else {
                            return Single.error(NetworkError.mappingError)
                        }
                    case .failure:
                        if let response = dataResponse.response {
                            let data = dataResponse.data.flatMap { try? JSONSerialization.jsonObject(with: $0, options: .allowFragments) }
                            return Single.error(NetworkError.serverError(status: response.statusCode, data: data))
                        } else {
                            return Single.error(NetworkError.noConnection)
                        }
                    }
                }
    }

}

extension NetworkManager {

    class NetworkLogger: EventMonitor {
        private var logger: Logger?

        let queue = DispatchQueue(label: "Network Logger", qos: .background)

        init(logger: Logger?) {
            self.logger = logger
        }

        func requestDidResume(_ request: Request) {
            logger?.verbose("API OUT: \(request)")
        }

        func request<Value>(_ request: DataRequest, didParseResponse response: DataResponse<Value, AFError>) {
            switch response.result {
            case .success(let result):
                logger?.verbose("API IN: \(request)\n\(result)")
            case .failure:
                logger?.error("API IN: \(request)\n\(response)")
            }
        }

    }

}

extension NetworkManager {

    class JsonMapperResponseSerializer<T>: ResponseSerializer {
        private let mapper: (Any) throws -> T

        private let jsonSerializer = JSONResponseSerializer()

        init(mapper: @escaping (Any) throws -> T) {
            self.mapper = mapper
        }

        func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) throws -> T {
            let json = try jsonSerializer.serialize(request: request, response: response, data: data, error: error)
            return try mapper(json)
        }

    }

}
