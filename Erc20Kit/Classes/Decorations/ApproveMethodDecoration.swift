import EthereumKit
import BigInt

public class ApproveMethodDecoration: ContractMethodDecoration {
    public let spender: Address
    public let value: BigUInt

    init(spender: Address, value: BigUInt) {
        self.spender = spender
        self.value = value

        super.init()
    }

    public override func tags(fromAddress: Address, toAddress: Address, userAddress: Address) -> [String] {
        [toAddress.hex, "eip20Approve"]
    }

}
