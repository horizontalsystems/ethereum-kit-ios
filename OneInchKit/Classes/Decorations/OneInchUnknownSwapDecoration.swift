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

    public override func tags() -> [TransactionTag] {
        var tags = [TransactionTag]()

        if let tokenIn = tokenAmountIn?.token {
            tags.append(tag(token: tokenIn, type: .swap))
            tags.append(tag(token: tokenIn, type: .outgoing))
        }

        if let tokenOut = tokenAmountOut?.token {
            tags.append(tag(token: tokenOut, type: .swap))
            tags.append(tag(token: tokenOut, type: .incoming))
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
