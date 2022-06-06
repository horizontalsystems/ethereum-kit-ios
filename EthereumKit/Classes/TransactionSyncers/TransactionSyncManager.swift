import RxSwift
import BigInt

class TransactionSyncManager {
    private let transactionManager: TransactionManager
    private let disposeBag = DisposeBag()

    private var syncers = [ITransactionSyncer]()

    private let queue = DispatchQueue(label: "io.horizontal-systems.ethereum-kit.transaction-sync-manager", qos: .utility)

    private let stateSubject = PublishSubject<SyncState>()
    var state: SyncState = .notSynced(error: Kit.SyncError.notStarted) {
        didSet {
            if state != oldValue {
                stateSubject.onNext(state)
            }
        }
    }

    init(transactionManager: TransactionManager) {
        self.transactionManager = transactionManager
    }

    private func handle(transactionsArray: [[Transaction]]) {
        let transactions = Array(transactionsArray.joined())

        var dictionary = [Data: Transaction]()

        for transaction in transactions {
            if let existingTransaction = dictionary[transaction.hash] {
                dictionary[transaction.hash] = merge(lhsTransaction: existingTransaction, rhsTransaction: transaction)
            } else {
                dictionary[transaction.hash] = transaction
            }
        }

        transactionManager.handle(transactions: Array(dictionary.values))
    }

    private func merge(lhsTransaction lhs: Transaction, rhsTransaction rhs: Transaction) -> Transaction {
        Transaction(
                hash: lhs.hash,
                timestamp: lhs.timestamp,
                isFailed: lhs.isFailed,
                blockNumber: lhs.blockNumber ?? rhs.blockNumber,
                transactionIndex: lhs.transactionIndex ?? rhs.transactionIndex,
                from: lhs.from ?? rhs.from,
                to: lhs.to ?? rhs.to,
                value: lhs.value ?? rhs.value,
                input: lhs.input ?? rhs.input,
                nonce: lhs.nonce ?? rhs.nonce,
                gasPrice: lhs.gasPrice ?? rhs.gasPrice,
                maxFeePerGas: lhs.maxFeePerGas ?? rhs.maxFeePerGas,
                maxPriorityFeePerGas: lhs.maxPriorityFeePerGas ?? rhs.maxPriorityFeePerGas,
                gasLimit: lhs.gasLimit ?? rhs.gasLimit,
                gasUsed: lhs.gasUsed ?? rhs.gasUsed,
                replacedWith: lhs.replacedWith ?? rhs.replacedWith
        )
    }

    private func handleSuccess(transactionsArray: [[Transaction]]) {
        queue.async {
            self.handle(transactionsArray: transactionsArray)
            self.state = .synced
        }
    }

    private func handleError(error: Error) {
        queue.async {
            self.state = .notSynced(error: error)
        }
    }

    private func _sync() {
        guard !state.syncing else {
            return
        }

        state = .syncing(progress: nil)

        Single.zip(syncers.map { syncer in
                    syncer.transactionsSingle().catchErrorJustReturn([])
                })
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .subscribe(
                        onSuccess: { [weak self] transactionsArray in
                            self?.handleSuccess(transactionsArray: transactionsArray)
                        },
                        onError: { [weak self] error in
                            self?.handleError(error: error)
                        }
                )
                .disposed(by: disposeBag)
    }

}

extension TransactionSyncManager {

    var stateObservable: Observable<SyncState> {
        stateSubject.asObservable()
    }

    func add(syncer: ITransactionSyncer) {
        queue.async {
            self.syncers.append(syncer)
        }
    }

    func sync() {
        queue.async {
            self._sync()
        }
    }

}
