import RxSwift

class NotSyncedTransactionManager {
    private var pool: NotSyncedTransactionPool
    private var storage: ITransactionSyncerStateStorage

    var notSyncedTransactionsSignal: Signal {
        pool.notSyncedTransactionsSignal
    }

    init(pool: NotSyncedTransactionPool, storage: ITransactionSyncerStateStorage) {
        self.pool = pool
        self.storage = storage
    }

}

extension NotSyncedTransactionManager: ITransactionSyncerDelegate {

    func transactionSyncerState(id: String) -> TransactionSyncerState? {
        storage.transactionSyncerState(id: id)
    }

    func update(transactionSyncerState: TransactionSyncerState) {
        storage.save(transactionSyncerState: transactionSyncerState)
    }

    public func add(notSyncedTransactions: [NotSyncedTransaction]) {
        pool.add(notSyncedTransactions: notSyncedTransactions)
    }

    public func notSyncedTransactions(limit: Int) -> [NotSyncedTransaction] {
        pool.notSyncedTransactions(limit: limit)
    }

    public func remove(notSyncedTransaction: NotSyncedTransaction) {
        pool.remove(notSyncedTransaction: notSyncedTransaction)
    }

    public func update(notSyncedTransaction: NotSyncedTransaction) {
        pool.update(notSyncedTransaction: notSyncedTransaction)
    }

}
