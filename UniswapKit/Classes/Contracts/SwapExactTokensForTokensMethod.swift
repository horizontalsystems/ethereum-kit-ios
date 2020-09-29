import EthereumKit
import BigInt

class SwapExactTokensForTokensMethod: ContractMethod {
    private let amountIn: BigUInt
    private let amountOutMin: BigUInt
    private let path: [Address]
    private let to: Address
    private let deadline: BigUInt

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
        let supporting = supportingFeeOnTransfer ? "SupportingFeeOnTransferTokens" : ""
        return "swapExactTokensForTokens\(supporting)(uint256,uint256,address[],address,uint256)"
    }

    override var arguments: [Any] {
        [amountIn, amountOutMin, path, to, deadline]
    }

}
