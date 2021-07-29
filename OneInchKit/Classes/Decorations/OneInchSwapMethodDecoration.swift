import EthereumKit
import BigInt

public class OneInchSwapMethodDecoration: OneInchMethodDecoration {
    public let tokenIn: Token
    public let tokenOut: Token
    public let amountIn: BigUInt
    public let amountOutMin: BigUInt
    public let amountOut: BigUInt?
    public let flags: BigUInt
    public let permit: Data
    public let data: Data
    public let recipient: Address

    public init(tokenIn: Token, tokenOut: Token, amountIn: BigUInt, amountOutMin: BigUInt, amountOut: BigUInt?, flags: BigUInt, permit: Data, data: Data, recipient: Address) {
        self.tokenIn = tokenIn
        self.tokenOut = tokenOut
        self.amountIn = amountIn
        self.amountOutMin = amountOutMin
        self.amountOut = amountOut
        self.flags = flags
        self.permit = permit
        self.data = data
        self.recipient = recipient

        super.init()
    }

    public override func tags(fromAddress: Address, toAddress: Address, userAddress: Address) -> [String] {
        var tags: [String] = [toAddress.hex, "swap"]

        switch tokenIn {
        case .evmCoin: tags.append(contentsOf: ["\(TransactionTag.evmCoin)_outgoing", TransactionTag.evmCoin, "outgoing"])
        case .eip20Coin(let tokenAddress): tags.append(contentsOf: ["\(tokenAddress.hex)_outgoing", tokenAddress.hex, "outgoing"])
        }

        if recipient == userAddress {
            switch tokenOut {
            case .evmCoin: tags.append(contentsOf: ["\(TransactionTag.evmCoin)_incoming", TransactionTag.evmCoin, "incoming"])
            case .eip20Coin(let tokenAddress): tags.append(contentsOf: ["\(tokenAddress.hex)_incoming", tokenAddress.hex, "incoming"])
            }
        }

        return tags
    }

}
