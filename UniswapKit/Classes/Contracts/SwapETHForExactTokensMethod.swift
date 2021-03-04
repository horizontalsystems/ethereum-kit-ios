import EthereumKit
import BigInt

class SwapETHForExactTokensMethod: ContractMethod {
    static let methodSignature = "swapETHForExactTokens(uint256,address[],address,uint256)"

    let amountOut: BigUInt
    let path: [Address]
    let to: Address
    let deadline: BigUInt

    init(amountOut: BigUInt, path: [Address], to: Address, deadline: BigUInt) {
        self.amountOut = amountOut
        self.path = path
        self.to = to
        self.deadline = deadline

        super.init()
    }

    override var methodSignature: String { SwapETHForExactTokensMethod.methodSignature }

    override var arguments: [Any] {
        [amountOut, path, to, deadline]
    }

}
