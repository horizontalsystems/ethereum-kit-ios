import RxSwift

class TransactionManager {
    private let scheduler = ConcurrentDispatchQueueScheduler(queue: DispatchQueue(label: "transactionManager.ethereum_transactions", qos: .background))
    private let disposeBag = DisposeBag()

    weak var delegate: ITransactionManagerDelegate?

    private let storage: ITransactionStorage & IInternalTransactionStorage
    private let transactionsProvider: ITransactionsProvider

    private var delayTime = 3
    private let delayTimeIncreaseFactor = 2
    private var retryCount = 0

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

    func sync(delayTime: Int? = nil) {
        let lastTransaction = storage.lastTransaction
        let lastTransactionBlockHeight = lastTransaction?.blockNumber ?? 0
        let lastInternalTransactionBlockHeight = storage.lastInternalTransactionBlockHeight ?? 0

        var requestsSingle = Single.zip(
                transactionsProvider.transactionsSingle(startBlock: lastTransactionBlockHeight + 1),
                transactionsProvider.internalTransactionsSingle(startBlock: lastInternalTransactionBlockHeight + 1)
        ) { ($0, $1)}

        if let delayTime = delayTime {
            requestsSingle = requestsSingle.delaySubscription(DispatchTimeInterval.seconds(delayTime), scheduler: scheduler)
        }

        requestsSingle
                .subscribeOn(scheduler)
                .subscribe(onSuccess: { [weak self] transactions, internalTransactions in
                    guard let manager = self else {
                        return
                    }

                    if transactions.isEmpty && internalTransactions.isEmpty && manager.retryCount > 0 {
                        manager.retryCount -= 1
                        manager.delayTime = manager.delayTime * manager.delayTimeIncreaseFactor
                        manager.sync(delayTime: manager.delayTime)
                        return
                    }

                    manager.retryCount = 0
                    manager.update(transactions: transactions, internalTransactions: internalTransactions, lastTransactionHash: lastTransaction?.hash)
                    manager.syncState = .synced
                }, onError: { [weak self] error in
                    self?.retryCount = 0
                    self?.syncState = .notSynced(error: error)
                })
                .disposed(by: disposeBag)
    }

}

extension TransactionManager: ITransactionManager {

    var source: String {
        transactionsProvider.source
    }

    func refresh(delay: Bool) {
        if case .syncing = syncState {
            return
        }

        syncState = .syncing(progress: nil)

        if delay {
            retryCount = 5
            delayTime = 3

            sync(delayTime: delayTime)
        } else {
            sync()
        }
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
