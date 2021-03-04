import EthereumKit
import BigInt

class SwapExactETHForTokensMethod: ContractMethod {
    static func methodSignature(supportingFeeOnTransfer: Bool) -> String {
        let supporting = supportingFeeOnTransfer ? "SupportingFeeOnTransferTokens" : ""
        return "swapExactETHForTokens\(supporting)(uint256,address[],address,uint256)"
    }

    let amountOutMin: BigUInt
    let path: [Address]
    let to: Address
    let deadline: BigUInt

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
        SwapExactETHForTokensMethod.methodSignature(supportingFeeOnTransfer: supportingFeeOnTransfer)
    }

    override var arguments: [Any] {
        [amountOutMin, path, to, deadline]
    }

}
