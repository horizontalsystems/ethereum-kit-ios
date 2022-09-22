import BigInt
import EthereumKit

public class Eip1155SetApprovalForAllDecoration: TransactionDecoration {
    public let contractAddress: Address
    public let `operator`: Address
    public let approved: Bool

    init(contractAddress: Address, `operator`: Address, approved: Bool) {
        self.contractAddress = contractAddress
        self.operator = `operator`
        self.approved = approved

        super.init()
    }

    public override func tags() -> [String] {
        ["eip1155Approve", contractAddress.hex]
    }

}
