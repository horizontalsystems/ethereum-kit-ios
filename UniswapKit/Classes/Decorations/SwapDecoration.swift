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

    private func tags(token: Token, type: String) -> [String] {
        switch token {
        case .evmCoin: return ["\(TransactionTag.evmCoin)_\(type)", TransactionTag.evmCoin, type]
        case .eip20Coin(let tokenAddress, _): return ["\(tokenAddress.hex)_\(type)", tokenAddress.hex, type]
        }
    }

    public override func tags() -> [String] {
        var tags: [String] = [contractAddress.hex, "swap"]

        tags.append(contentsOf: self.tags(token: tokenIn, type: "outgoing"))

        if recipient == nil {
            tags.append(contentsOf: self.tags(token: tokenOut, type: "incoming"))
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
