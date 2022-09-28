import BigInt
import EthereumKit

public class OutgoingEip20Decoration: TransactionDecoration {
    public let contractAddress: Address
    public let to: Address
    public let value: BigUInt
    public let sentToSelf: Bool
    public let tokenInfo: TokenInfo?

    init(contractAddress: Address, to: Address, value: BigUInt, sentToSelf: Bool, tokenInfo: TokenInfo?) {
        self.contractAddress = contractAddress
        self.to = to
        self.value = value
        self.sentToSelf = sentToSelf
        self.tokenInfo = tokenInfo

        super.init()
    }

    public override func tags() -> [TransactionTag] {
        [
            TransactionTag(type: .outgoing, protocol: .eip20, contractAddress: contractAddress)
        ]
    }

}
