import EthereumKit

open class OneInchMethodDecoration: ContractMethodDecoration {

    public enum Token {
        case evmCoin
        case eip20Coin(address: Address)
    }

}
