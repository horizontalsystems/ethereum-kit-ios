public class GetStorageAtRequest: IRequest {
    public let id: Int

    let contractAddress: Data
    let position: String
    let blockNumber: Int

    public init(contractAddress: Data, position: String, blockNumber: Int) {
        self.id = RandomHelper.shared.randomInt
        self.contractAddress = contractAddress
        self.position = position
        self.blockNumber = blockNumber
    }

}
