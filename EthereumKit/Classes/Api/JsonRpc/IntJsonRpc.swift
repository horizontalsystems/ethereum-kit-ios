class IntJsonRpc: JsonRpc<Int> {

    override func parse(result: Any) throws -> Int {
        guard let hexString = result as? String else {
            throw ParseError.invalidResult(value: result)
        }

        guard let value = Int(hexString.stripHexPrefix(), radix: 16) else {
            throw ParseError.invalidHex(value: hexString)
        }

        return value
    }

}

extension IntJsonRpc {

    enum ParseError: Error {
        case invalidResult(value: Any)
        case invalidHex(value: String)
    }

}
