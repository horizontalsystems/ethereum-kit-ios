import EthereumKit
import BigInt

public class ApproveTransactionDecoration: TransactionDecoration {
    public let spender: Address
    public let value: BigUInt

    init(spender: Address, value: BigUInt) {
        self.spender = spender
        self.value = value

        super.init()
        tags.append("eip20Approve")
    }

}
