class GetTransactionCountJsonRpc: IntJsonRpc {
    let address: Address
    let defaultBlockParameter: DefaultBlockParameter

    init(address: Address, defaultBlockParameter: DefaultBlockParameter) {
        self.address = address
        self.defaultBlockParameter = defaultBlockParameter

        super.init(
                method: "eth_getTransactionCount",
                params: [address.hex, defaultBlockParameter.raw]
        )
    }

}
