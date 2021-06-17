import EthereumKit
import BigInt

public class SwapEventDecoration: ContractEventDecoration {
    static let signature = ContractEvent(name: "Swap", arguments: [.address, .uint256, .uint256, .uint256, .uint256, .address]).signature

    public let sender: Address
    public let amount0In: BigUInt
    public let amount1In: BigUInt
    public let amount0Out: BigUInt
    public let amount1Out: BigUInt
    public let to: Address

    init(contractAddress: Address, sender: Address, amount0In: BigUInt, amount1In: BigUInt, amount0Out: BigUInt, amount1Out: BigUInt, to: Address) {
        self.sender = sender
        self.amount0In = amount0In
        self.amount1In = amount1In
        self.amount0Out = amount0Out
        self.amount1Out = amount1Out
        self.to = to

        super.init(contractAddress: contractAddress)
    }

    public override func tags(fromAddress: Address, toAddress: Address, userAddress: Address) -> [String] {
        if fromAddress == userAddress {
            return ["swap"]
        } else {
            return []
        }
    }

}
