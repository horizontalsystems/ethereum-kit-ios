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

    func removeLeadingZeros() -> String {
        self.replacingOccurrences(of: "^0+", with: "", options: .regularExpression)
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

    public func roundedString(decimal: Int) -> String {
        let poweredDecimal = self * pow(10, decimal)
        let handler = NSDecimalNumberHandler(roundingMode: .plain, scale: 0, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
        let roundedDecimal = NSDecimalNumber(decimal: poweredDecimal).rounding(accordingToBehavior: handler).decimalValue

        return String(describing: roundedDecimal)
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

    static func fromIncubed(callable: @escaping () throws -> Element) -> Single<Element> {
        Single.from(callable: callable)
        .catchError { error -> PrimitiveSequence<SingleTrait, Element> in
            if error is IncubedRpcApiProvider.IncubedError {
                return .error(error)
            }

            return .error(IncubedRpcApiProvider.IncubedError.notReachable)
        }
    }

}
