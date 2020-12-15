class GetTransactionReceiptJsonRpc: JsonRpc<RpcTransactionReceipt?> {

    init(transactionHash: Data) {
        super.init(
                method: "eth_getTransactionReceipt",
                params: [transactionHash.toHexString()]
        )
    }

    override func parse(result: Any?) throws -> RpcTransactionReceipt? {
        try result.map { try RpcTransactionReceipt(JSONObject: $0) }
    }

}
