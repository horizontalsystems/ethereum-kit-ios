import EthereumKit
import BigInt

public class OneInchUnoswapMethodDecoration: OneInchMethodDecoration {
    public let tokenIn: Token
    public let tokenOut: Token?
    public let amountIn: BigUInt
    public let amountOutMin: BigUInt
    public let amountOut: BigUInt?
    public let params: [Data]

    public init(tokenIn: Token, tokenOut: Token?, amountIn: BigUInt, amountOutMin: BigUInt, amountOut: BigUInt?, params: [Data]) {
        self.tokenIn = tokenIn
        self.tokenOut = tokenOut
        self.amountIn = amountIn
        self.amountOutMin = amountOutMin
        self.amountOut = amountOut
        self.params = params

        super.init()
    }

    public override func tags(fromAddress: Address, toAddress: Address, userAddress: Address) -> [String] {
        var tags: [String] = [toAddress.hex, "swap"]

        switch tokenIn {
        case .evmCoin: tags.append(contentsOf: ["\(TransactionTag.evmCoin)_outgoing", TransactionTag.evmCoin, "outgoing"])
        case .eip20Coin(let tokenAddress): tags.append(contentsOf: ["\(tokenAddress.hex)_outgoing", tokenAddress.hex, "outgoing"])
        }

        if let tokenOut = tokenOut {
            switch tokenOut {
            case .evmCoin: tags.append(contentsOf: ["\(TransactionTag.evmCoin)_incoming", TransactionTag.evmCoin, "incoming"])
            case .eip20Coin(let tokenAddress): tags.append(contentsOf: ["\(tokenAddress.hex)_incoming", tokenAddress.hex, "incoming"])
            }
        }

        return tags
    }

}
