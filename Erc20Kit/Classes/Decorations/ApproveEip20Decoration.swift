import BigInt
import EthereumKit

public class ApproveEip20Decoration: TransactionDecoration {
    public let contractAddress: Address
    public let spender: Address
    public let value: BigUInt

    init(contractAddress: Address, spender: Address, value: BigUInt) {
        self.contractAddress = contractAddress
        self.spender = spender
        self.value = value

        super.init()
    }

    public override func tags() -> [String] {
        [contractAddress.hex, "eip20Approve"]
    }

}
