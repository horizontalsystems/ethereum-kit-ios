import EthereumKit
import BigInt

class TransferMethod: ContractMethod {
    private let to: Address
    private let value: BigUInt

    init(to: Address, value: BigUInt) {
        self.to = to
        self.value = value

        super.init()
    }

    override var methodSignature: String { "transfer(address,uint256)" }
    override var arguments: [Any] { [to, value] }
}
