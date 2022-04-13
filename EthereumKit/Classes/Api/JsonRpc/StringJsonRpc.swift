class StringJsonRpc: JsonRpc<String> {

    override func parse(result: Any) throws -> String {
        guard let string = result as? String else {
            throw JsonRpcResponse.ResponseError.invalidResult(value: result)
        }

        return string
    }

}
