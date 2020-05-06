import RxSwift
import Alamofire
import HsToolKit

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
