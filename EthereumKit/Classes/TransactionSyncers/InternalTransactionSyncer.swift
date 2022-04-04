import RxSwift
import BigInt

class InternalTransactionSyncer {
    private let provider: ITransactionProvider
    private let storage: ITransactionStorage

    init(provider: ITransactionProvider, storage: ITransactionStorage) {
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

    func transactionsSingle(lastBlockNumber: Int) -> Single<[Transaction]> {
        provider.internalTransactionsSingle(startBlock: lastBlockNumber + 1)
                .do(onSuccess: { [weak self] transactions in
                    self?.handle(transactions: transactions)
                })
                .map { transactions in
                    transactions.map { tx in
                        Transaction(
                                hash: tx.hash,
                                timestamp: tx.timestamp,
                                isFailed: false,
                                blockNumber: tx.blockNumber
                        )
                    }
                }
    }

}
