import RxSwift
import BigInt

class UserInternalTransactionSyncer: AbstractTransactionSyncer {
    private let provider: EtherscanTransactionProvider
    private let storage: ITransactionStorage
    private let scheduler = ConcurrentDispatchQueueScheduler(qos: .background)

    weak var listener: ITransactionSyncerListener?

    init(provider: EtherscanTransactionProvider, storage: ITransactionStorage) {
        self.provider = provider
        self.storage = storage

        super.init(id: "user_internal_transaction_syncer")
    }

    private func handle(transactions: [InternalTransaction]) {
        if !transactions.isEmpty {
            storage.save(internalTransactions: transactions)

            if let blockNumber = transactions.first?.blockNumber {
                update(lastSyncBlockNumber: blockNumber)
            }

            var notSyncedTransactions = [NotSyncedTransaction]()
            var syncedTransactions = [FullTransaction]()

            for etherscanTransaction in transactions {
                if let transaction = storage.transaction(hash: etherscanTransaction.hash) {
                    syncedTransactions.append(transaction)
                } else {
                    notSyncedTransactions.append(NotSyncedTransaction(hash: etherscanTransaction.hash))
                }
            }

            if !notSyncedTransactions.isEmpty {
                delegate.add(notSyncedTransactions: notSyncedTransactions)
            }

            if !syncedTransactions.isEmpty {
                listener?.onTransactionsSynced(fullTransactions: syncedTransactions)
            }
        }

        state = .synced
    }

    private func sync() {
        guard !state.syncing else {
            return
        }

        let single = provider.internalTransactionsSingle(startBlock: lastSyncBlockNumber + 1)

        state = .syncing(progress: nil)

        single
                .observeOn(scheduler)
                .subscribe(
                        onSuccess: { [weak self] transactions in
                            self?.handle(transactions: transactions)
                        },
                        onError: { [weak self] error in
                            self?.state = .notSynced(error: error)
                        }
                )
                .disposed(by: disposeBag)
    }

    override func onLastBlockNumber(blockNumber: Int) {
        sync()
    }

}
