import EthereumKit
import BigInt

public class TransferEventDecoration: ContractEventDecoration {
    static let signature = ContractEvent(name: "Transfer", arguments: [.address, .address, .uint256]).signature

    public let from: Address
    public let to: Address
    public let value: BigUInt

    init(contractAddress: Address, from: Address, to: Address, value: BigUInt) {
        self.from = from
        self.to = to
        self.value = value

        super.init(contractAddress: contractAddress)
    }

    public override func tags(fromAddress: Address, toAddress: Address, userAddress: Address) -> [String] {
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
