import EthereumKit
import BigInt

public class SwapMethodDecoration: ContractMethodDecoration {
    public let trade: Trade
    public let tokenIn: Token
    public let tokenOut: Token
    public let to: Address
    public let deadline: BigUInt

    public init(trade: Trade, tokenIn: Token, tokenOut: Token, to: Address, deadline: BigUInt) {
        self.trade = trade
        self.tokenIn = tokenIn
        self.tokenOut = tokenOut
        self.to = to
        self.deadline = deadline

        super.init()
    }

    public enum Trade {
        case exactIn(amountIn: BigUInt, amountOutMin: BigUInt, amountOut: BigUInt? = nil)
        case exactOut(amountOut: BigUInt, amountInMax: BigUInt, amountIn: BigUInt? = nil)
    }

    public enum Token {
        case evmCoin
        case eip20Coin(address: Address)
    }

    public override func tags(fromAddress: Address, toAddress: Address, userAddress: Address) -> [String] {
        var tags: [String] = [toAddress.hex, "swap"]

        switch tokenIn {
        case .evmCoin: tags.append(contentsOf: ["\(TransactionTag.evmCoin)_outgoing", TransactionTag.evmCoin, "outgoing"])
        case .eip20Coin(let tokenAddress): tags.append(contentsOf: ["\(tokenAddress.hex)_outgoing", tokenAddress.hex, "outgoing"])
        }

        if to == userAddress {
            switch tokenOut {
            case .evmCoin: tags.append(contentsOf: ["\(TransactionTag.evmCoin)_incoming", TransactionTag.evmCoin, "incoming"])
            case .eip20Coin(let tokenAddress): tags.append(contentsOf: ["\(tokenAddress.hex)_incoming", tokenAddress.hex, "incoming"])
            }
        }

        return tags
    }

}
