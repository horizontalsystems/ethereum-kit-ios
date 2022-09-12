import EthereumKit
import BigInt

public class Eip1155TransferEventInstance: ContractEventInstance {
    static let transferSingleSignature = ContractEvent(name: "TransferSingle", arguments: [.address, .address, .address, .uint256, .uint256]).signature
    static let transferBatchSignature = ContractEvent(name: "TransferBatch", arguments: [.address, .address, .address, .uint256Array, .uint256Array]).signature

    public let from: Address
    public let to: Address
    public let tokenId: BigUInt
    public let value: BigUInt

    public let tokenInfo: TokenInfo?

    init(contractAddress: Address, from: Address, to: Address, tokenId: BigUInt, value: BigUInt, tokenInfo: TokenInfo? = nil) {
        self.from = from
        self.to = to
        self.tokenId = tokenId
        self.value = value
        self.tokenInfo = tokenInfo

        super.init(contractAddress: contractAddress)
    }

    public override func tags(userAddress: Address) -> [String] {
        var tags: [String] = [contractAddress.hex]

        if from == userAddress {
            tags.append("\(contractAddress.hex)_outgoing")
            tags.append("outgoing")
        }

        if to == userAddress {
            tags.append("\(contractAddress.hex)_incoming")
            tags.append("incoming")
        }

        return tags
    }

}
