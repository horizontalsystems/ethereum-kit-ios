class GetBlockByNumberJsonRpc: JsonRpc<Block> {
    let number: Int

    init(number: Int) {
        self.number = number

        super.init(
                method: "eth_getBlockByNumber",
                params: ["0x" + String(number, radix: 16), false]
        )
    }

    override func parse(result: Any) throws -> Block {
        guard let block = Block(json: result) else {
            throw ParseError.invalidResult(value: result)
        }

        return block
    }

}

extension GetBlockByNumberJsonRpc {

    enum ParseError: Error {
        case invalidResult(value: Any)
    }

}
