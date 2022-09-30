import RxSwift
import BigInt

class InternalTransactionSyncer {
    private let provider: ITransactionProvider
    private let storage: TransactionStorage

    init(provider: ITransactionProvider, storage: TransactionStorage) {
        self.provider = provider
        self.storage = storage
    }

    private func handle(transactions: [ProviderInternalTransaction]) {
        guard !transactions.isEmpty else {
            return
        }

        let internalTransactions = transactions.map { tx in
            InternalTransaction(
                    hash: tx.hash,
                    blockNumber: tx.blockNumber,
                    from: tx.from,
                    to: tx.to,
                    value: tx.value,
                    traceId: tx.traceId
            )
        }

        storage.save(internalTransactions: internalTransactions)
    }

}

extension InternalTransactionSyncer: ITransactionSyncer {

    func transactionsSingle() -> Single<([Transaction], Bool)> {
        let lastBlockNumber = storage.lastInternalTransaction()?.blockNumber ?? 0
        let initial = lastBlockNumber == 0

        return provider.internalTransactionsSingle(startBlock: lastBlockNumber + 1)
                .do(onSuccess: { [weak self] transactions in
                    self?.handle(transactions: transactions)
                })
                .map { transactions in
                    let array = transactions.map { tx in
                        Transaction(
                                hash: tx.hash,
                                timestamp: tx.timestamp,
                                isFailed: false,
                                blockNumber: tx.blockNumber
                        )
                    }

                    return (array, initial)
                }
                .catchErrorJustReturn(([], initial))
    }

}
