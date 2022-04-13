class GetBlockByNumberJsonRpc: JsonRpc<RpcBlock> {

    init(number: Int) {
        super.init(
                method: "eth_getBlockByNumber",
                params: ["0x" + String(number, radix: 16), false]
        )
    }

    override func parse(result: Any) throws -> RpcBlock {
        try RpcBlock(JSONObject: result)
    }

}
