class GetBlockByNumberJsonRpc: JsonRpc<Block> {

    init(number: Int) {
        super.init(
                method: "eth_getBlockByNumber",
                params: ["0x" + String(number, radix: 16), false]
        )
    }

    override func parse(result: Any) throws -> Block {
        guard let block = Block(json: result) else {
            throw JsonRpcResponse.ResponseError.invalidResult(value: result)
        }

        return block
    }

}
