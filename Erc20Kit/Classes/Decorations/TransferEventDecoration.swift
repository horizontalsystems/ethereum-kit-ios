import EthereumKit
import BigInt

public class TransferEventDecoration: ContractEventDecoration {
    static let signature = ContractEvent(name: "Transfer", arguments: [.address, .address, .uint256]).signature

    public let from: Address
    public let to: Address
    public let value: BigUInt

    public let tokenName: String?
    public let tokenSymbol: String?
    public let tokenDecimal: Int?

    init(contractAddress: Address, from: Address, to: Address, value: BigUInt, tokenName: String? = nil, tokenSymbol: String? = nil, tokenDecimal: Int? = nil) {
        self.from = from
        self.to = to
        self.value = value
        self.tokenName = tokenName
        self.tokenSymbol = tokenSymbol
        self.tokenDecimal = tokenDecimal

        super.init(contractAddress: contractAddress)
    }

    public override func tags(userAddress: Address) -> [String] {
        var tags: [String] = [contractAddress.hex, "eip20Transfer"]

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
