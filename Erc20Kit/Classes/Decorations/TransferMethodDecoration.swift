import EthereumKit
import BigInt

public class TransferMethodDecoration: ContractMethodDecoration {
    public let to: Address
    public let value: BigUInt

    init(to: Address, value: BigUInt) {
        self.to = to
        self.value = value

        super.init()
    }

    public override func tags(fromAddress: Address, toAddress: Address, userAddress: Address) -> [String] {
        var tags: [String] = [toAddress.hex, "eip20Transfer"]

        if fromAddress == userAddress {
            tags.append("\(toAddress.hex)_outgoing")
            tags.append("outgoing")
        }

        if to == userAddress {
            tags.append("\(toAddress.hex)_incoming")
            tags.append("incoming")
        }

        return tags
    }

}
