import EthereumKit
import BigInt

public class TransferEventDecoration: EventDecoration {
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

    override open var tags: [String] {
        [contractAddress.hex, "eip20Transfer"]
    }

}
