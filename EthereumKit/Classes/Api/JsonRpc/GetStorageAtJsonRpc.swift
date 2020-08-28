import Foundation

class GetStorageAtJsonRpc: DataJsonRpc {
    let contractAddress: Address
    let positionData: Data
    let defaultBlockParameter: DefaultBlockParameter

    init(contractAddress: Address, positionData: Data, defaultBlockParameter: DefaultBlockParameter) {
        self.contractAddress = contractAddress
        self.positionData = positionData
        self.defaultBlockParameter = defaultBlockParameter

        super.init(
                method: "eth_getStorageAt",
                params: [contractAddress.hex, positionData.toHexString(), defaultBlockParameter.raw]
        )
    }

}
