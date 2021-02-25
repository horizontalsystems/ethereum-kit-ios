import ObjectMapper

public enum JsonRpcResponse {
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

    public struct SuccessResponse: ImmutableMappable {
        let version: String
        let id: Int
        var result: Any?

        public init(map: Map) throws {
            version = try map.value("jsonrpc")
            id = try map.value("id")

            guard map["result"].isKeyPresent else {
                throw MapError(key: "result", currentValue: nil, reason: nil)
            }

            result = try map.value("result")
        }
    }

    public struct ErrorResponse: ImmutableMappable {
        let version: String
        let id: Int
        let error: RpcError

        public init(map: Map) throws {
            version = try map.value("jsonrpc")
            id = try map.value("id")
            error = try map.value("error")
        }
    }

    public struct RpcError: ImmutableMappable {
        public let code: Int
        public let message: String
        public let data: Any?

        public init(map: Map) throws {
            code = try map.value("code")
            message = try map.value("message")
            data = try? map.value("data")
        }
    }

    public enum ResponseError: Error {
        case rpcError(JsonRpcResponse.RpcError)
        case invalidResult(value: Any?)
    }

}
