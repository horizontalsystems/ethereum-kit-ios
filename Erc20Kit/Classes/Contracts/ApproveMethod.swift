import EthereumKit
import BigInt

class ApproveMethod: ContractMethod {
    private let spender: Address
    private let value: BigUInt

    init(spender: Address, value: BigUInt) {
        self.spender = spender
        self.value = value

        super.init()
    }

    override var methodSignature: String { "approve(address,uint256)" }
    override var arguments: [Any] { [spender, value] }
}

extension ApproveMethod: IErc20ContractMethodWithTransactions {

    func erc20Transactions(ethTx: EthereumKit.Transaction) -> [Transaction] {
        let newTx = Transaction(transactionHash: ethTx.hash,
                transactionIndex: 0,
                from: ethTx.from,
                to: spender,
                value: value,
                timestamp: ethTx.timestamp,
                type: TransactionType.approve)

        newTx.blockHash = ethTx.blockHash
        newTx.blockNumber = ethTx.blockNumber

        return [newTx]
    }

}
