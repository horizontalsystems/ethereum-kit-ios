import RxSwift

class NotSyncedTransactionPool {
    private let storage: ITransactionStorage
    let notSyncedTransactionsSignal = Signal()

    init(storage: ITransactionStorage) {
        self.storage = storage
    }

    func add(notSyncedTransactions: [NotSyncedTransaction]) {
        let syncedTransactionHashes = storage.getHashesFromTransactions()
        let newTransactions = notSyncedTransactions.filter { !syncedTransactionHashes.contains($0.hash) }
        print("NotSyncedTransactionPool adding \(notSyncedTransactions.count) transactions")

        storage.add(notSyncedTransactions: newTransactions)
        notSyncedTransactionsSignal.onNext(())
    }

    func remove(notSyncedTransaction: NotSyncedTransaction) {
        storage.remove(notSyncedTransaction: notSyncedTransaction)
    }

    func update(notSyncedTransaction: NotSyncedTransaction) {
        storage.update(notSyncedTransaction: notSyncedTransaction)
    }

    func getNotSyncedTransactions(limit: Int) -> [NotSyncedTransaction] {
        storage.getNotSyncedTransactions(limit: limit)
    }

}
