import UIExtensions
import RxSwift

public extension Data {

    init<T>(from value: T) {
        var value = value
        self.init(buffer: UnsafeBufferPointer(start: &value, count: 1))
    }

    func toHexString() -> String {
        "0x" + self.hex
    }

    var bytes: Array<UInt8> {
        Array(self)
    }

    func to<T>(type: T.Type) -> T {
        self.withUnsafeBytes { $0.load(as: T.self) }
    }

}

extension Int {

    var flowControlLog: String {
        "\(Double(self) / 1_000_000)"
    }

}

extension String {

    var data: Data {
        self.data(using: .utf8) ?? Data()
    }

    func removeLeadingZeros() -> String {
        self == "0" ? self : self.replacingOccurrences(of: "^0+", with: "", options: .regularExpression)
    }

    func addHexPrefix() -> String {
        let prefix = "0x"

        if self.hasPrefix(prefix) {
            return self
        }

        return prefix.appending(self)
    }

}

extension Decimal {

    public func rounded(decimal: Int) -> Decimal {
        let poweredDecimal = self * pow(10, decimal)
        let handler = NSDecimalNumberHandler(roundingMode: .plain, scale: 0, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
        return NSDecimalNumber(decimal: poweredDecimal).rounding(accordingToBehavior: handler).decimalValue
    }

    public func roundedString(decimal: Int) -> String {
        String(describing: rounded(decimal: decimal))
    }

}

extension Collection {

    var json: String? {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: self) else {
            return nil
        }
        return String(bytes: jsonData, encoding: String.Encoding.utf8)
    }

}

extension PrimitiveSequence where Trait == SingleTrait {

    static func from(callable: @escaping () throws -> Element) -> Single<Element> {
        Single.create { observer in
            do {
                let result = try callable()
                observer(SingleEvent.success(result))
            } catch {
                observer(SingleEvent.error(error))
            }

            return Disposables.create()
        }
    }

//    static func fromIncubed(callable: @escaping () throws -> Element) -> Single<Element> {
//        Single.from(callable: callable)
//        .catchError { error -> PrimitiveSequence<SingleTrait, Element> in
//            if error is IncubedRpcApiProvider.IncubedError {
//                return .error(error)
//            }
//
//            return .error(IncubedRpcApiProvider.IncubedError.notReachable)
//        }
//    }

}

public struct RetryOptions<T> {
    let initialDelayTime: Int = 5
    let delayIncreaseFactor: Int = 3
    let maxRetry: Int = 3
    let mustRetry: (T) -> Bool

    public init(mustRetry: @escaping (T) -> Bool) {
        self.mustRetry = mustRetry
    }
}

public extension PrimitiveSequence where Trait == SingleTrait {

    enum RetryError: Error {
        case mustRetry
    }

    func retryWith(options: RetryOptions<Element>, scheduler: SchedulerType) -> PrimitiveSequence<SingleTrait, Element> {
        var delayTime = options.initialDelayTime
        var retryCount = 1

        return self
                .flatMap { Single.just($0) }
                .delaySubscription(DispatchTimeInterval.seconds(options.initialDelayTime), scheduler: scheduler)
                .map { element -> Element in
                    if options.mustRetry(element) && retryCount < options.maxRetry {
                        throw RetryError.mustRetry
                    }

                    return element
                }
                .retryWhen { errorObservable in
                    errorObservable
                            .filter { error in
                                if let error = error as? RetryError {
                                    delayTime = delayTime * options.delayIncreaseFactor
                                    retryCount += 1

                                    return error == .mustRetry
                                }

                                return false
                            }
                            .flatMap { _ in
                                Observable<Int>.timer(DispatchTimeInterval.seconds(delayTime), scheduler: scheduler)
                            }
                }
    }

}
