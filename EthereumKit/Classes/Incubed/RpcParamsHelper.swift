import Foundation
import BigInt

class RpcParamsHelper {

    private static func dropQuotesAndHex(text: String) -> String {
        var result = text
        if result.hasPrefix("\"") {
            result.removeFirst()
        }
        if result.hasSuffix("\"") {
            result.removeLast()
        }
        if result.hasPrefix("0x") {
            result.removeFirst(2)
        }

        return result
    }

    private static func map(_ any: Any) -> Any? {
        switch any {
        case let int as Int: return "0x\(String(int, radix: 16))"
        case let dictionary as [String: Any]: return convert(dictionary)
        case let array as [Any]: return convert(array)
        case let data as Data: return data.toHexString()
        case let bigInt as BigUInt: return bigInt.serialize().toHexString()
        case Optional<Any>.none: return nil
        default: return any
        }
    }

    static func convert(_ array: [Any]) -> [Any] {
        array.compactMap(map)
    }

    static func convert(_ dictionary: [String: Any]) -> [String: Any] {
        dictionary.compactMapValues(map)
    }

    static func convert<T: Collection>(_ json: String) throws -> T? {
        guard let data = json.data(using: .utf8) else {
            return nil
        }
        return try JSONSerialization.jsonObject(with: data, options: []) as? T
    }


    static func convert<T: FixedWidthInteger>(_ json: String) -> T? {
        let numberString = dropQuotesAndHex(text: json)
        return T(numberString, radix: 16)
    }

    static func convert(_ json: String) -> BigUInt? {
        let numberString = dropQuotesAndHex(text: json)
        return BigUInt(numberString, radix: 16)
    }

}
