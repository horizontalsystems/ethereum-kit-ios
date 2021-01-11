import RxSwift

class NotSyncedTransactionPool {
    private let storage: ITransactionStorage
    let notSyncedTransactionsSignal = Signal()
    let queue = DispatchQueue(label: "not_synced_tx_pool_queue", qos: .background)

    init(storage: ITransactionStorage) {
        self.storage = storage
    }

    func add(notSyncedTransactions: [NotSyncedTransaction]) {
        queue.async { [weak self] in
            guard let pool = self else {
                return
            }

            let syncedTransactionHashes = pool.storage.hashesFromTransactions()
            let newTransactions = notSyncedTransactions.filter {
                !syncedTransactionHashes.contains($0.hash)
            }

            pool.storage.add(notSyncedTransactions: newTransactions)
            pool.notSyncedTransactionsSignal.onNext(())
        }
    }

    func remove(notSyncedTransaction: NotSyncedTransaction) {
        queue.sync {
            storage.remove(notSyncedTransaction: notSyncedTransaction)
        }
    }

    func update(notSyncedTransaction: NotSyncedTransaction) {
        queue.sync {
            storage.update(notSyncedTransaction: notSyncedTransaction)
        }
    }

    func notSyncedTransactions(limit: Int) -> [NotSyncedTransaction] {
        storage.notSyncedTransactions(limit: limit)
    }

}
