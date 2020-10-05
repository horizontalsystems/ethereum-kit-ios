import EthereumKit

protocol IErc20ContractMethodWithTransactions {
    func erc20Transactions(ethTx: EthereumKit.Transaction) -> [Transaction]
}
