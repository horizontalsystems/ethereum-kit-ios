import ObjectMapper

class JsonRpc<T> {
    private let method: String
    private let params: [Any]

    init(method: String, params: [Any] = []) {
        self.method = method
        self.params = params
    }

    func parameters(id: Int = 1) -> [String: Any] {
        [
            "jsonrpc": "2.0",
            "method": method,
            "params": params,
            "id": id
        ]
    }

    func parse(result: Any) throws -> T {
        fatalError("This method should be overridden")
    }

    func parse(response: JsonRpcResponse) throws -> T {
        switch response {
        case .success(let successResponse):
            guard let result = successResponse.result else {
                throw JsonRpcResponse.ResponseError.invalidResult(value: successResponse.result)
            }

            return try parse(result: result)
        case .error(let errorResponse):
            throw JsonRpcResponse.ResponseError.rpcError(errorResponse.error)
        }
    }

}
