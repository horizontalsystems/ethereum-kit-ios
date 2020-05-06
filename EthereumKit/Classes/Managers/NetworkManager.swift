import RxSwift
import Alamofire

class NetworkManager {
    let session: Session

    init(logger: Logger? = nil) {
        let networkLogger = NetworkLogger(logger: logger)
        session = Session(eventMonitors: [networkLogger])
    }

    func single<Mapper: IApiMapper>(request: DataRequest, mapper: Mapper) -> Single<Mapper.T> {
        Single<Mapper.T>.create { observer in
            let requestReference = request.response(queue: DispatchQueue.global(qos: .background), responseSerializer: JsonMapperResponseSerializer<Mapper>(mapper: mapper))
            { response in
                switch response.result {
                case .success(let result):
                    observer(.success(result))
                case .failure(let error):
                    observer(.error(NetworkManager.unwrap(error: error)))
                }
            }

            return Disposables.create {
                requestReference.cancel()
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
            case .failure(let error):
                logger?.error("API IN: \(request)\n\(NetworkManager.unwrap(error: error))")
            }
        }

    }

}

extension NetworkManager {

    class JsonMapperResponseSerializer<Mapper: IApiMapper>: ResponseSerializer {
        private let mapper: Mapper

        private let jsonSerializer = JSONResponseSerializer()

        init(mapper: Mapper) {
            self.mapper = mapper
        }

        func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) throws -> Mapper.T {
            guard let response = response else {
                throw RequestError.noResponse(reason: error?.localizedDescription)
            }

            let json = try? jsonSerializer.serialize(request: request, response: response, data: data, error: nil)
            return try mapper.map(statusCode: response.statusCode, data: json)
        }

    }

}

extension NetworkManager {

    static func unwrap(error: Error) -> Error {
        if case let AFError.responseSerializationFailed(reason) = error, case let .customSerializationFailed(error) = reason {
            return error
        }

        return error
    }

}

extension NetworkManager {

    enum RequestError: Error {
        case invalidResponse(statusCode: Int, data: Any?)
        case noResponse(reason: String?)
    }

}

protocol IApiMapper {
    associatedtype T
    func map(statusCode: Int, data: Any?) throws -> T
}

extension NetworkManager {

    func singleOld(request: DataRequest) -> Single<AFDataResponse<Any>> {
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
