import Foundation

class DataJsonRpc: JsonRpc<Data> {

    override func parse(result: Any) throws -> Data {
        guard let hexString = result as? String else {
            throw ParseError.invalidResult(value: result)
        }

        guard let value = Data(hex: hexString) else {
            throw ParseError.invalidHex(value: hexString)
        }

        return value
    }

}

extension DataJsonRpc {

    enum ParseError: Error {
        case invalidResult(value: Any)
        case invalidHex(value: String)
    }

}
