import RxSwift

class TransactionManager {
    private let disposeBag = DisposeBag()

    weak var delegate: ITransactionManagerDelegate?

    private let storage: ITransactionStorage & IInternalTransactionStorage
    private let transactionsProvider: ITransactionsProvider

    private(set) var syncState: SyncState = .notSynced(error: Kit.SyncError.notStarted) {
        didSet {
            if syncState != oldValue {
                delegate?.onUpdate(transactionsSyncState: syncState)
            }
        }
    }

    init(storage: ITransactionStorage & IInternalTransactionStorage, transactionsProvider: ITransactionsProvider) {
        self.storage = storage
        self.transactionsProvider = transactionsProvider
    }

    private func update(transactions: [Transaction], internalTransactions: [InternalTransaction], lastTransactionHash: Data?) {
        storage.save(transactions: transactions)
        storage.save(internalTransactions: internalTransactions)

        let transactionsWithInternals: [TransactionWithInternal] = transactions.compactMap { transaction in
            let internalTransactions = internalTransactions.filter {
                $0.hash.hex == transaction.hash.hex
            }

            let transactionWithInternal = TransactionWithInternal(transaction: transaction, internalTransactions: internalTransactions)

            if !isEmpty(transactionWithInternal: transactionWithInternal) {
                return transactionWithInternal
            } else {
                return nil
            }
        }
        delegate?.onUpdate(transactionsWithInternal: transactionsWithInternals)
    }

    private func isEmpty(transactionWithInternal: TransactionWithInternal) -> Bool {
        transactionWithInternal.transaction.value == 0 && transactionWithInternal.internalTransactions.isEmpty
    }

}

extension TransactionManager: ITransactionManager {

    var source: String {
        transactionsProvider.source
    }

    func refresh() {
        syncState = .syncing(progress: nil)

        let lastTransaction = storage.lastTransaction
        let lastTransactionBlockHeight = lastTransaction?.blockNumber ?? 0
        let lastInternalTransactionBlockHeight = storage.lastInternalTransactionBlockHeight ?? 0

        Single.zip(
                transactionsProvider.transactionsSingle(startBlock: lastTransactionBlockHeight + 1),
                transactionsProvider.internalTransactionsSingle(startBlock: lastInternalTransactionBlockHeight + 1)
        ) { ($0, $1)}
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onSuccess: { [weak self] transactions, internalTransactions in
                    self?.update(transactions: transactions, internalTransactions: internalTransactions, lastTransactionHash: lastTransaction?.hash)
                    self?.syncState = .synced
                }, onError: { [weak self] error in
                    self?.syncState = .notSynced(error: error)
                })
                .disposed(by: disposeBag)
    }

    func transactionsSingle(fromHash: Data?, limit: Int?) -> Single<[TransactionWithInternal]> {
        storage.transactionsSingle(fromHash: fromHash, limit: limit)
    }

    func transaction(hash: Data) -> TransactionWithInternal? {
        storage.transaction(hash: hash)
    }

    func handle(sentTransaction: Transaction) {
        storage.save(transactions: [sentTransaction])

        let transactionWithInternal = TransactionWithInternal(transaction: sentTransaction)

        if !isEmpty(transactionWithInternal: transactionWithInternal) {
            delegate?.onUpdate(transactionsWithInternal: [transactionWithInternal])
        }
    }

}
