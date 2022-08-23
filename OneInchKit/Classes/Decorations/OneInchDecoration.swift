import EthereumKit
import Erc20Kit
import BigInt

open class OneInchDecoration: TransactionDecoration {
    public let contractAddress: Address

    public init(contractAddress: Address) {
        self.contractAddress = contractAddress
    }

    public override func tags() -> [String] {
        [contractAddress.hex, "swap"]
    }

    func tags(token: Token, type: String) -> [String] {
        switch token {
        case .evmCoin: return ["\(TransactionTag.evmCoin)_\(type)", TransactionTag.evmCoin, type]
        case .eip20Coin(let tokenAddress, _): return ["\(tokenAddress.hex)_\(type)", tokenAddress.hex, type]
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
