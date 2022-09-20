import BigInt
import EthereumKit

public class OutgoingEip1155Decoration: TransactionDecoration {
    public let contractAddress: Address
    public let to: Address
    public let tokenId: BigUInt
    public let value: BigUInt
    public let sentToSelf: Bool
    public let tokenInfo: TokenInfo?

    init(contractAddress: Address, to: Address, tokenId: BigUInt, value: BigUInt, sentToSelf: Bool, tokenInfo: TokenInfo?) {
        self.contractAddress = contractAddress
        self.to = to
        self.tokenId = tokenId
        self.value = value
        self.sentToSelf = sentToSelf
        self.tokenInfo = tokenInfo

        super.init()
    }

    public override func tags() -> [String] {
        ["eip1155Transfer", contractAddress.hex, "\(contractAddress.hex)_outgoing", "outgoing"]
    }

}
