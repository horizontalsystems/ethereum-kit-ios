import Foundation

class InternalTransactionsDecorator {
    private let storage: ITransactionStorage

    init(storage: ITransactionStorage) {
        self.storage = storage
    }

}

extension InternalTransactionsDecorator: IDecorator {

    public func decorate(transactionData: TransactionData) -> ContractMethodDecoration? {
        nil
    }

    public func decorate(fullTransaction: FullTransaction, fullRpcTransaction: FullRpcTransaction) {
        fullTransaction.internalTransactions = fullRpcTransaction.internalTransactions
    }

    func decorate(fullTransactionMap: [Data: FullTransaction]) {
        let internalTransactions: [InternalTransaction]

        if fullTransactionMap.count > 100 {
            internalTransactions = storage.internalTransactions()
        } else {
            let hashes = fullTransactionMap.values.map { $0.transaction.hash }
            internalTransactions = storage.internalTransactions(hashes: hashes)
        }

        for internalTransaction in internalTransactions {
            fullTransactionMap[internalTransaction.hash]?.internalTransactions.append(internalTransaction)
        }
    }

}
