import EthereumKit
import BigInt

public class Eip721TransferEventInstance: ContractEventInstance {
    static let signature = ContractEvent(name: "Transfer", arguments: [.address, .address, .uint256]).signature

    public let from: Address
    public let to: Address
    public let tokenId: BigUInt

    public let tokenInfo: TokenInfo?

    init(contractAddress: Address, from: Address, to: Address, tokenId: BigUInt, tokenInfo: TokenInfo? = nil) {
        self.from = from
        self.to = to
        self.tokenId = tokenId
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
