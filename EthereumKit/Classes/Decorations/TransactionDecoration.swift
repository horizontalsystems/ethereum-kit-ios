import BigInt

public enum TransactionDecoration {
    case unknown(methodId: Data, inputArguments: Data)
    case recognized(method: String, arguments: [Any])
    case eip20Transfer(to: Address, value: BigUInt)
    case eip20Approve(spender: Address, value: BigUInt)
    case swap(trade: Trade, tokenIn: Token, tokenOut: Token, to: Address, deadline: BigUInt)

    public enum Trade {
        case exactIn(amountIn: BigUInt, amountOutMin: BigUInt, amountOut: BigUInt? = nil)
        case exactOut(amountOut: BigUInt, amountInMax: BigUInt, amountIn: BigUInt? = nil)
    }

    public enum Token {
        case evmCoin
        case eip20Coin(address: Address)
    }

    var name: String? {
        switch self {
        case .unknown: return nil
        case .recognized(let method, _): return method
        case .eip20Transfer: return "eip20Transfer"
        case .eip20Approve: return "eip20Approve"
        case .swap: return "swap"
        }
    }

}
