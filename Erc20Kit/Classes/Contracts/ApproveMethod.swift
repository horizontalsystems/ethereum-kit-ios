import EthereumKit
import BigInt

class ApproveMethod: ContractMethod {
    static let methodSignature = "approve(address,uint256)"

    let spender: Address
    let value: BigUInt

    init(spender: Address, value: BigUInt) {
        self.spender = spender
        self.value = value

        super.init()
    }

    override var methodSignature: String { ApproveMethod.methodSignature }
    override var arguments: [Any] { [spender, value] }
}
