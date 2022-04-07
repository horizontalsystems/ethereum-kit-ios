import EthereumKit
import BigInt

public class OneInchUnoswapDecoration: OneInchDecoration {
    public let tokenIn: Token
    public let tokenOut: Token?
    public let amountIn: BigUInt
    public let amountOut: Amount
    public let params: [Data]

    public init(contractAddress: Address, tokenIn: Token, tokenOut: Token?, amountIn: BigUInt, amountOut: Amount, params: [Data]) {
        self.tokenIn = tokenIn
        self.tokenOut = tokenOut
        self.amountIn = amountIn
        self.amountOut = amountOut
        self.params = params

        super.init(contractAddress: contractAddress)
    }

    public override func tags() -> [String] {
        var tags = super.tags()

        tags.append(contentsOf: self.tags(token: tokenIn, type: "outgoing"))

        if let tokenOut = tokenOut {
            tags.append(contentsOf: self.tags(token: tokenOut, type: "incoming"))
        }

        return tags
    }

}
