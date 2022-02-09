import BigInt

class GasPriceJsonRpc: IntJsonRpc {

    init() {
        super.init(
                method: "eth_gasPrice",
                params: []
        )
    }

}
