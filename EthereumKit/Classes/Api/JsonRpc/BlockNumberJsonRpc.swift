class BlockNumberJsonRpc: IntJsonRpc {

    init() {
        super.init(method: "eth_blockNumber")
    }

}
