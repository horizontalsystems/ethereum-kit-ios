import BigInt

public enum TransactionDecoration {
    case transfer(from: Address, to: Address?, value: BigUInt)
    case eip20Transfer(to: Address, value: BigUInt, contractAddress: Address)
    case eip20Approve(spender: Address, value: BigUInt, contractAddress: Address)
    case swap(trade: Trade, tokenIn: Token, tokenOut: Token, to: Address, deadline: BigUInt)

    public enum Trade {
        case exactIn(amountIn: BigUInt, amountOutMin: BigUInt)
        case exactOut(amountOut: BigUInt, amountInMax: BigUInt)
    }

    public enum Token {
        case evmCoin
        case eip20Coin(address: Address)
    }

}
