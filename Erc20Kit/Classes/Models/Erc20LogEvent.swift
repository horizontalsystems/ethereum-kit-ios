import EthereumKit
import BigInt

enum Erc20LogEvent {
    static let transferSignature = ContractEvent(name: "Transfer", arguments: [.address, .address, .uint256]).signature
    static let approvalSignature = ContractEvent(name: "Approval", arguments: [.address, .address, .uint256]).signature

    case transfer(from: Address, to: Address, value: BigUInt)
    case approve(owner: Address, spender: Address, value: BigUInt)
}
