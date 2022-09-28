import EthereumKit
import Erc20Kit
import BigInt

open class OneInchDecoration: TransactionDecoration {
    public let contractAddress: Address

    public init(contractAddress: Address) {
        self.contractAddress = contractAddress
    }

    func tag(token: Token, type: TransactionTag.TagType) -> TransactionTag {
        switch token {
        case .evmCoin: return TransactionTag(type: type, protocol: .native)
        case .eip20Coin(let tokenAddress, _): return TransactionTag(type: type, protocol: .eip20, contractAddress: tokenAddress)
        }
    }

}

extension OneInchDecoration {

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
