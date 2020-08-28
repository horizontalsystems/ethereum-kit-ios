import Foundation

class CallJsonRpc: DataJsonRpc {
    let contractAddress: Address
    let data: Data
    let defaultBlockParameter: DefaultBlockParameter

    init(contractAddress: Address, data: Data, defaultBlockParameter: DefaultBlockParameter) {
        self.contractAddress = contractAddress
        self.data = data
        self.defaultBlockParameter = defaultBlockParameter

        super.init(
                method: "eth_call",
                params: [
                    ["to": contractAddress.hex, "data": data.toHexString()],
                    defaultBlockParameter.raw
                ]
        )
    }

}
