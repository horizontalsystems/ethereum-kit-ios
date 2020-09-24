import ObjectMapper

enum JsonRpcResponse {
    case success(SuccessResponse)
    case error(ErrorResponse)

    var id: Int {
        switch self {
        case .success(let response):
            return response.id
        case .error(let response):
            return response.id
        }
    }

    static func response(jsonObject: Any) -> JsonRpcResponse? {
        if let successResponse = try? SuccessResponse(JSONObject: jsonObject) {
            return .success(successResponse)
        }

        if let errorResponse = try? ErrorResponse(JSONObject: jsonObject) {
            return .error(errorResponse)
        }

        return nil
    }

}

extension JsonRpcResponse {

    struct SuccessResponse: ImmutableMappable {
        let version: String
        let id: Int
        var result: Any?

        init(map: Map) throws {
            version = try map.value("jsonrpc")
            id = try map.value("id")

            guard map["result"].isKeyPresent else {
                throw MapError(key: "result", currentValue: nil, reason: nil)
            }

            result = try map.value("result")
        }
    }

    struct ErrorResponse: ImmutableMappable {
        let version: String
        let id: Int
        let error: RpcError

        init(map: Map) throws {
            version = try map.value("jsonrpc")
            id = try map.value("id")
            error = try map.value("error")
        }
    }

    struct RpcError: ImmutableMappable {
        let code: Int
        let message: String
        let data: Any?

        init(map: Map) throws {
            code = try map.value("code")
            message = try map.value("message")
            data = try? map.value("data")
        }
    }

    enum ResponseError: Error {
        case rpcError(JsonRpcResponse.RpcError)
        case invalidResult(value: Any?)
    }

}
