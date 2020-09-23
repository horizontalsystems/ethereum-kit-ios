import ObjectMapper

struct RpcSubscriptionResponse: ImmutableMappable {
    let method: String
    let params: Params

    init(map: Map) throws {
        method = try map.value("method")
        params = try map.value("params")
    }
}

extension RpcSubscriptionResponse {

    struct Params: ImmutableMappable {
        let subscriptionId: Int
        let result: Any

        init(map: Map) throws {
            subscriptionId = try map.value("subscription", using: HexIntTransform())
            result = try map.value("result")
        }
    }

}
