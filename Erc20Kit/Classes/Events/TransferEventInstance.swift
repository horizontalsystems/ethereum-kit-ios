import EthereumKit
import BigInt

public class TransferEventInstance: ContractEventInstance {
    static let signature = ContractEvent(name: "Transfer", arguments: [.address, .address, .uint256]).signature

    public let from: Address
    public let to: Address
    public let value: BigUInt

    public let tokenInfo: TokenInfo?

    init(contractAddress: Address, from: Address, to: Address, value: BigUInt, tokenInfo: TokenInfo? = nil) {
        self.from = from
        self.to = to
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

public struct TokenInfo {
    public let tokenName: String
    public let tokenSymbol: String
    public let tokenDecimal: Int
}
