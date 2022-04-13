import Foundation

class DataJsonRpc: JsonRpc<Data> {

    override func parse(result: Any) throws -> Data {
        guard let hexString = result as? String, let value = Data(hex: hexString) else {
            throw JsonRpcResponse.ResponseError.invalidResult(value: result)
        }

        return value
    }

}
