import EthereumKit
import BigInt

public class TransferTransactionDecoration: TransactionDecoration {
    public let to: Address
    public let value: BigUInt

    init(to: Address, value: BigUInt) {
        self.to = to
        self.value = value

        super.init()
        tags.append("eip20Transfer")
    }

}
