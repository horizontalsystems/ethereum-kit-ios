import Foundation

class CallJsonRpc: DataJsonRpc {

    init(contractAddress: Address, data: Data, defaultBlockParameter: DefaultBlockParameter) {
        super.init(
                method: "eth_call",
                params: [
                    ["to": contractAddress.hex, "data": data.toHexString()],
                    defaultBlockParameter.raw
                ]
        )
    }

}
