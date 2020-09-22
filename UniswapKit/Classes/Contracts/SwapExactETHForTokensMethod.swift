import EthereumKit
import BigInt

class SwapExactETHForTokensMethod: ContractMethod {
    private let amountOutMin: BigUInt
    private let path: [Address]
    private let to: Address
    private let deadline: BigUInt

    private let supportingFeeOnTransfer: Bool

    init(amountOut: BigUInt, path: [Address], to: Address, deadline: BigUInt, supportingFeeOnTransfer: Bool = false) {
        self.amountOutMin = amountOut
        self.path = path
        self.to = to
        self.deadline = deadline
        self.supportingFeeOnTransfer = supportingFeeOnTransfer

        super.init()
    }

    override var methodSignature: String {
        let supporting = supportingFeeOnTransfer ? "SupportingFeeOnTransferTokens" : ""
        return "swapExactETHForTokens\(supporting)(uint256,address[],address,uint256)"
    }

    override var arguments: [Any] {
        [amountOutMin, path, to, deadline]
    }

}
