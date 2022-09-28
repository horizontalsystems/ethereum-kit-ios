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

    public override func tags(userAddress: Address) -> [TransactionTag] {
        var tags = [TransactionTag]()

        if from == userAddress {
            tags.append(TransactionTag(type: .outgoing, protocol: .eip20, contractAddress: contractAddress))
        }

        if to == userAddress {
            tags.append(TransactionTag(type: .incoming, protocol: .eip20, contractAddress: contractAddress))
        }

        return tags
    }

}

public struct TokenInfo {
    public let tokenName: String
    public let tokenSymbol: String
    public let tokenDecimal: Int
}
