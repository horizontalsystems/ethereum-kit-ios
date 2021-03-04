import EthereumKit
import BigInt

class SwapExactTokensForETHMethod: ContractMethod {
    static func methodSignature(supportingFeeOnTransfer: Bool) -> String {
        let supporting = supportingFeeOnTransfer ? "SupportingFeeOnTransferTokens" : ""
        return "swapExactTokensForETH\(supporting)(uint256,uint256,address[],address,uint256)"
    }

    let amountIn: BigUInt
    let amountOutMin: BigUInt
    let path: [Address]
    let to: Address
    let deadline: BigUInt

    private let supportingFeeOnTransfer: Bool

    init(amountIn: BigUInt, amountOutMin: BigUInt, path: [Address], to: Address, deadline: BigUInt, supportingFeeOnTransfer: Bool = false) {
        self.amountIn = amountIn
        self.amountOutMin = amountOutMin
        self.path = path
        self.to = to
        self.deadline = deadline
        self.supportingFeeOnTransfer = supportingFeeOnTransfer

        super.init()
    }

    override var methodSignature: String {
        SwapExactTokensForETHMethod.methodSignature(supportingFeeOnTransfer: supportingFeeOnTransfer)
    }

    override var arguments: [Any] {
        [amountIn, amountOutMin, path, to, deadline]
    }

}
