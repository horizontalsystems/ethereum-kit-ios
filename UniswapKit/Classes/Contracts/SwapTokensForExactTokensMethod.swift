import EthereumKit
import BigInt

class SwapTokensForExactTokensMethod: ContractMethod {
    private let amountOut: BigUInt
    private let amountInMax: BigUInt
    private let path: [Address]
    private let to: Address
    private let deadline: BigUInt

    init(amountOut: BigUInt, amountInMax: BigUInt, path: [Address], to: Address, deadline: BigUInt) {
        self.amountOut = amountOut
        self.amountInMax = amountInMax
        self.path = path
        self.to = to
        self.deadline = deadline

        super.init()
    }

    override var methodSignature: String { "swapTokensForExactTokens(uint256,uint256,address[],address,uint256)" }

    override var arguments: [Any] {
        [amountOut, amountInMax, path, to, deadline]
    }

}
