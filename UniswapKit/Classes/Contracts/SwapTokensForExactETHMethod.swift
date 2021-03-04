import EthereumKit
import BigInt

class SwapTokensForExactETHMethod: ContractMethod {
    static let methodSignature = "swapTokensForExactETH(uint256,uint256,address[],address,uint256)"

    let amountOut: BigUInt
    let amountInMax: BigUInt
    let path: [Address]
    let to: Address
    let deadline: BigUInt

    init(amountOut: BigUInt, amountInMax: BigUInt, path: [Address], to: Address, deadline: BigUInt) {
        self.amountOut = amountOut
        self.amountInMax = amountInMax
        self.path = path
        self.to = to
        self.deadline = deadline

        super.init()
    }

    override var methodSignature: String { SwapTokensForExactETHMethod.methodSignature }

    override var arguments: [Any] {
        [amountOut, amountInMax, path, to, deadline]
    }

}
