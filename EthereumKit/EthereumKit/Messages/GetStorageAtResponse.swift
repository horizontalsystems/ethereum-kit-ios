public class GetStorageAtResponse: IResponse {
    public let id: Int

    public let contractAddress: Data
    public let blockNumber: Int
    public let balanceValue: Data

    init(id: Int, contractAddress: Data, blockNumber: Int, balanceValue: Data) {
        self.id = id
        self.contractAddress = contractAddress
        self.blockNumber = blockNumber
        self.balanceValue = balanceValue
    }

}
