class GetTransactionReceiptJsonRpc: JsonRpc<TransactionReceipt?> {

    init(transactionHash: Data) {
        super.init(
                method: "eth_getTransactionReceipt",
                params: [transactionHash.toHexString()]
        )
    }

    override func parse(result: Any?) throws -> TransactionReceipt? {
        try result.map { try TransactionReceipt(JSONObject: $0) }
    }

}
