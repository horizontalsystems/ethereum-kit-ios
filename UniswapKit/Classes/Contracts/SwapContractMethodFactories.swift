import EthereumKit

class SwapContractMethodFactories: ContractMethodFactories {
    static let shared = SwapContractMethodFactories()

    override init() {
        super.init()
        register(factories: [
            SwapETHForExactTokensMethodFactory(),
            SwapExactETHForTokensMethodFactory(),
            SwapExactTokensForETHMethodFactory(),
            SwapExactTokensForTokensMethodFactory(),
            SwapTokensForExactETHMethodFactory(),
            SwapTokensForExactTokensMethodFactory(),
            SwapExactETHForTokensMethodSupportingFeeOnTransferFactory(),
            SwapExactTokensForETHMethodSupportingFeeOnTransferFactory(),
            SwapExactTokensForTokensMethodSupportingFeeOnTransferFactory(),
        ])
    }

}
