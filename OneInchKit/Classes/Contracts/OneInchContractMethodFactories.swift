import EthereumKit

class OneInchContractMethodFactories: ContractMethodFactories {
    static let shared = OneInchContractMethodFactories()

    override init() {
        super.init()
        register(factories: [
            UnoswapMethodFactory(),
            SwapMethodFactory()
        ])
    }

}
