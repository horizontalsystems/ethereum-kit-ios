class SubscribeJsonRpc: StringJsonRpc {

    init(params: [Any]) {
        super.init(
                method: "eth_subscribe",
                params: params
        )
    }

}
