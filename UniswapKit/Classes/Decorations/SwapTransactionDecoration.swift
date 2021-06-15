import EthereumKit
import BigInt

public class SwapTransactionDecoration: TransactionDecoration {
    public let trade: Trade
    public let tokenIn: Token
    public let tokenOut: Token
    public let to: Address
    public let deadline: BigUInt

    init(trade: Trade, tokenIn: Token, tokenOut: Token, to: Address, deadline: BigUInt) {
        self.trade = trade
        self.tokenIn = tokenIn
        self.tokenOut = tokenOut
        self.to = to
        self.deadline = deadline

        super.init()
        tags.append("swap")
    }

    public enum Trade {
        case exactIn(amountIn: BigUInt, amountOutMin: BigUInt, amountOut: BigUInt? = nil)
        case exactOut(amountOut: BigUInt, amountInMax: BigUInt, amountIn: BigUInt? = nil)
    }

    public enum Token {
        case evmCoin
        case eip20Coin(address: Address)
    }

}
