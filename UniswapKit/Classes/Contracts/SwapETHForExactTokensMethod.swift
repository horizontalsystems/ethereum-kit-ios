import EthereumKit
import BigInt

class SwapETHForExactTokensMethod: ContractMethod {
    private let amountOut: BigUInt
    private let path: [Address]
    private let to: Address
    private let deadline: BigUInt

    init(amountOut: BigUInt, path: [Address], to: Address, deadline: BigUInt) {
        self.amountOut = amountOut
        self.path = path
        self.to = to
        self.deadline = deadline

        super.init()
    }

    override var methodSignature: String { "swapETHForExactTokens(uint256,address[],address,uint256)" }

    override var arguments: [Any] {
        [amountOut, path, to, deadline]
    }

}
