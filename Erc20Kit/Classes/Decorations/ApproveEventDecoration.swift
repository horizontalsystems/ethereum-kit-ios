import EthereumKit
import BigInt

public class ApproveEventDecoration: ContractEventDecoration {
    static let signature = ContractEvent(name: "Approval", arguments: [.address, .address, .uint256]).signature

    public let owner: Address
    public let spender: Address
    public let value: BigUInt

    init(contractAddress: Address, owner: Address, spender: Address, value: BigUInt) {
        self.owner = owner
        self.spender = spender
        self.value = value

        super.init(contractAddress: contractAddress)
    }

    public override func tags(fromAddress: Address, toAddress: Address, userAddress: Address) -> [String] {
        []
    }

}
