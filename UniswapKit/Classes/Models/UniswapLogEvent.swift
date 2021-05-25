import EthereumKit
import BigInt

enum UniswapLogEvent {
    static let swapSignature = ContractEvent(name: "Swap", arguments: [.address, .uint256, .uint256, .uint256, .uint256, .address]).signature

    case swap(sender: Address, amount0In: BigUInt, amount1In: BigUInt, amount0Out: BigUInt, amount1Out: BigUInt, to: Address)
}
