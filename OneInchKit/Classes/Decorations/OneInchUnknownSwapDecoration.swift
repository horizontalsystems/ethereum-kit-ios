import EthereumKit
import BigInt

public class OneInchUnknownSwapDecoration: OneInchDecoration {
    public let tokenAmountIn: TokenAmount?
    public let tokenAmountOut: TokenAmount?

    init(contractAddress: Address, tokenAmountIn: TokenAmount?, tokenAmountOut: TokenAmount?) {
        self.tokenAmountIn = tokenAmountIn
        self.tokenAmountOut = tokenAmountOut

        super.init(contractAddress: contractAddress)
    }

    public override func tags() -> [String] {
        var tags = super.tags()

        if let tokenIn = tokenAmountIn?.token {
            tags.append(contentsOf: self.tags(token: tokenIn, type: "outgoing"))
        }

        if let tokenOut = tokenAmountOut?.token {
            tags.append(contentsOf: self.tags(token: tokenOut, type: "incoming"))
        }

        return tags
    }

}

extension OneInchUnknownSwapDecoration {

    public struct TokenAmount {
        public let token: Token
        public let value: BigUInt
    }

}
