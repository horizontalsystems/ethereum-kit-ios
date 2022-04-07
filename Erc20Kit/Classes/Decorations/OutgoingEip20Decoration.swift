import BigInt
import EthereumKit

public class OutgoingEip20Decoration: TransactionDecoration {
    public let contractAddress: Address
    public let to: Address
    public let value: BigUInt
    public let sentToSelf: Bool

    init(contractAddress: Address, to: Address, value: BigUInt, sentToSelf: Bool) {
        self.contractAddress = contractAddress
        self.to = to
        self.value = value
        self.sentToSelf = sentToSelf

        super.init()
    }

    public override func tags() -> [String] {
        ["eip20Transfer", contractAddress.hex, "\(contractAddress.hex)_outgoing", "outgoing"]
    }

}
