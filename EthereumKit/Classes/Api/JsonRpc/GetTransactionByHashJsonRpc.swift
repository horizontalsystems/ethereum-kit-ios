class GetTransactionByHashJsonRpc: JsonRpc<[String: Any]?> {
    let transactionHash: Data

    init(transactionHash: Data) {
        self.transactionHash = transactionHash

        super.init(
                method: "eth_getTransactionByHash",
                params: [transactionHash.toHexString()]
        )
    }

    override func parse(result: Any) throws -> [String: Any]? {
        result as? [String: Any]
    }

}
