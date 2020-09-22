import EthereumKit

class Erc20Contract {

    init() {
        ContractMethodFactories.shared.register(factory: ApproveMethodFactory())
    }

    func getErc20TransactionsFromEthTransaction(ethTx: EthereumKit.Transaction) -> [Transaction] {
        let contractMethod = ContractMethodFactories.shared.createMethod(input: ethTx.input)

        return (contractMethod as? IErc20ContractMethodWithTransactions)?.erc20Transactions(ethTx: ethTx) ?? []
    }

}
