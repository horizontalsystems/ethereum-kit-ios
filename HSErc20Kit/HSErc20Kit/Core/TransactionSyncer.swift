class TransactionSyncer {

    weak var delegate: ITransactionSyncerDelegate?

    let storage: GrdbStorage
    let tokensHolder: TokensHolder
    let tokenStates: TokenStates
    let dataProvider: DataProvider

    var lastTransactionsSyncBlockHeight: Int
    var syncing = false

    init(storage: GrdbStorage, tokensHolder: TokensHolder, tokenStates: TokenStates, dataProvider: DataProvider) {
        self.storage = storage
        self.tokensHolder = tokensHolder
        self.tokenStates = tokenStates
        self.dataProvider = dataProvider
        self.lastTransactionsSyncBlockHeight = storage.lastTransactionBlockHeight() ?? 0
    }

    private func onTransactionsReceived(transactions: [Transaction], blockNumber: Int) {
        storage.save(transactions: transactions)
        lastTransactionsSyncBlockHeight = blockNumber

        let transactionsByToken: [Data: [Transaction]] = Dictionary(grouping: transactions, by: { $0.contractAddress })

        for (contractAddress, _) in tokensHolder.tokens {
            delegate?.onTransactionsUpdated(contractAddress: contractAddress, transactions: transactionsByToken[contractAddress] ?? [Transaction](), blockNumber: blockNumber)
        }

        syncing = false
    }

}

extension TransactionSyncer: ITransactionSyncer {

    func sync(forBlock blockNumber: Int) {
        for (contractAddress, _) in tokensHolder.tokens {
            tokenStates.set(state: .syncing, to: contractAddress)
        }

        guard lastTransactionsSyncBlockHeight < blockNumber, !syncing else {
            return
        }

        syncing = true
        dataProvider.getLogs(from: lastTransactionsSyncBlockHeight + 1, to: blockNumber, completionFunction: onTransactionsReceived)
    }

}
