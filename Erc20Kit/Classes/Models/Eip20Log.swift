import EthereumKit
import BigInt

public enum Eip20Log {
    case transfer(from: Address, to: Address, value: BigUInt)
    case approve(owner: Address, spender: Address, value: BigUInt)
}
