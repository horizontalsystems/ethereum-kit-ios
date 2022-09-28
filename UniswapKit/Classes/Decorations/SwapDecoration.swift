import EthereumKit
import Erc20Kit
import BigInt

public class SwapDecoration: TransactionDecoration {
    public let contractAddress: Address
    public let amountIn: Amount
    public let amountOut: Amount
    public let tokenIn: Token
    public let tokenOut: Token
    public let recipient: Address?
    public let deadline: BigUInt

    public init(contractAddress: Address, amountIn: Amount, amountOut: Amount, tokenIn: Token, tokenOut: Token, recipient: Address?, deadline: BigUInt) {
        self.contractAddress = contractAddress
        self.amountIn = amountIn
        self.amountOut = amountOut
        self.tokenIn = tokenIn
        self.tokenOut = tokenOut
        self.recipient = recipient
        self.deadline = deadline

        super.init()
    }

    private func tag(token: Token, type: TransactionTag.TagType) -> TransactionTag {
        switch token {
        case .evmCoin: return TransactionTag(type: type, protocol: .native)
        case .eip20Coin(let tokenAddress, _): return TransactionTag(type: type, protocol: .eip20, contractAddress: tokenAddress)
        }
    }

    public override func tags() -> [TransactionTag] {
        var tags = [
            tag(token: tokenIn, type: .swap),
            tag(token: tokenOut, type: .swap),
            tag(token: tokenIn, type: .outgoing)
        ]

        if recipient == nil {
            tags.append(tag(token: tokenOut, type: .incoming))
        }

        return tags
    }

}

extension SwapDecoration {

    public enum Amount {
        case exact(value: BigUInt)
        case extremum(value: BigUInt)
    }

    public enum Token {
        case evmCoin
        case eip20Coin(address: Address, tokenInfo: TokenInfo?)

        public var tokenInfo: TokenInfo? {
            switch self {
            case .eip20Coin(_, let tokenInfo): return tokenInfo
            default: return nil
            }
        }
    }

}
