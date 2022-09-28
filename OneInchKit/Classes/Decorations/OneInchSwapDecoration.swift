import EthereumKit
import BigInt

public class OneInchSwapDecoration: OneInchDecoration {
    public let tokenIn: Token
    public let tokenOut: Token
    public let amountIn: BigUInt
    public let amountOut: Amount
    public let flags: BigUInt
    public let permit: Data
    public let data: Data
    public let recipient: Address?

    public init(contractAddress: Address, tokenIn: Token, tokenOut: Token, amountIn: BigUInt, amountOut: Amount, flags: BigUInt, permit: Data, data: Data, recipient: Address?) {
        self.tokenIn = tokenIn
        self.tokenOut = tokenOut
        self.amountIn = amountIn
        self.amountOut = amountOut
        self.flags = flags
        self.permit = permit
        self.data = data
        self.recipient = recipient

        super.init(contractAddress: contractAddress)
    }

    public override func tags() -> [TransactionTag] {
        var tags = [TransactionTag]()

        tags.append(tag(token: tokenIn, type: .swap))
        tags.append(tag(token: tokenOut, type: .swap))

        tags.append(tag(token: tokenIn, type: .outgoing))

        if recipient == nil {
            tags.append(tag(token: tokenOut, type: .incoming))
        }

        return tags
    }

}
