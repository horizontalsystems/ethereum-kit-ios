import RxSwift

class TransactionInternalTransactionSyncer: AbstractTransactionSyncer {
    private let provider: EtherscanTransactionProvider
    private let storage: ITransactionStorage
    private var watchers = [ITransactionWatcher]()

    weak var listener: ITransactionSyncerListener?

    init(provider: EtherscanTransactionProvider, storage: ITransactionStorage) {
        self.provider = provider
        self.storage = storage

        super.init(id: "transaction_internal_transaction_syncer")
    }

    private func sync() {
        guard !state.syncing else {
            return
        }

        doSync()
    }

    private func doSync() {
        guard let notSyncedTransaction = storage.notSyncedInternalTransaction() else {
            state = .synced
            return
        }

        state = .syncing(progress: nil)

        provider.internalTransactionsSingle(transactionHash: notSyncedTransaction)
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(
                        onSuccess: { [weak self] internalTransactions in
                            self?.handle(notSyncedTransaction: notSyncedTransaction, internalTransactions: internalTransactions)
                        },
                        onError: { [weak self] in
                            self?.state = .notSynced(error: $0)
                        }
                )
                .disposed(by: disposeBag)
    }

    private func handle(notSyncedTransaction: NotSyncedInternalTransaction, internalTransactions: [InternalTransaction]) {
        guard !internalTransactions.isEmpty else {
            if notSyncedTransaction.retryCount < 10 {
                notSyncedTransaction.retryCount += 1
                storage.save(notSyncedInternalTransaction: notSyncedTransaction)
            } else {
                storage.remove(notSyncedInternalTransaction: notSyncedTransaction)
            }
            doSync()
            return
        }

        storage.save(internalTransactions: internalTransactions)
        storage.remove(notSyncedInternalTransaction: notSyncedTransaction)

        let fullTransactions = storage.fullTransactions(byHashes: [notSyncedTransaction.hash])
        listener?.onTransactionsSynced(fullTransactions: fullTransactions)

        doSync()
    }

    override func onLastBlockNumber(blockNumber: Int) {
        sync()
    }

}

extension TransactionInternalTransactionSyncer {

    func add(watcher: ITransactionWatcher) {
        watchers.append(watcher)
    }

    func sync(transactions: [FullTransaction]) {
        let confirmedTransactions = transactions.filter { $0.receiptWithLogs != nil }

        for transaction in confirmedTransactions {
            for watcher in watchers {
                if watcher.needInternalTransactions(fullTransaction: transaction) {
                    storage.save(notSyncedInternalTransaction: NotSyncedInternalTransaction(hash: transaction.transaction.hash, retryCount: 0))
                    sync()
                    break
                }
            }
        }
    }

}
