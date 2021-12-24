import EthereumKit

open class OneInchMethodDecoration: ContractMethodDecoration {

    public enum Token {
        case evmCoin
        case eip20Coin(address: Address)
    }

    public override func tags(fromAddress: Address, toAddress: Address, userAddress: Address) -> [String] {
        [toAddress.hex, "swap"]
    }

}
