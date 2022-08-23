import RxSwift
import BigInt

class TransactionSyncManager {
    private let transactionManager: TransactionManager
    private let disposeBag = DisposeBag()

    private var _syncers = [ITransactionSyncer]()

    private let queue = DispatchQueue(label: "io.horizontal-systems.ethereum-kit.transaction-sync-manager", qos: .utility)

    private let stateSubject = PublishSubject<SyncState>()
    private var _state: SyncState = .notSynced(error: Kit.SyncError.notStarted) {
        didSet {
            if _state != oldValue {
                stateSubject.onNext(_state)
            }
        }
    }

    init(transactionManager: TransactionManager) {
        self.transactionManager = transactionManager
    }

    private func _handle(resultArray: [([Transaction], Bool)]) {
        let transactions = Array(resultArray.map { $0.0 }.joined())
        let initial = resultArray.map { $0.1 }.allSatisfy { $0 }

        var dictionary = [Data: Transaction]()

        for transaction in transactions {
            if let existingTransaction = dictionary[transaction.hash] {
                dictionary[transaction.hash] = _merge(lhsTransaction: existingTransaction, rhsTransaction: transaction)
            } else {
                dictionary[transaction.hash] = transaction
            }
        }

        transactionManager.handle(transactions: Array(dictionary.values), initial: initial)
    }

    private func _merge(lhsTransaction lhs: Transaction, rhsTransaction rhs: Transaction) -> Transaction {
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

    private func handleSuccess(resultArray: [([Transaction], Bool)]) {
        queue.async {
            self._handle(resultArray: resultArray)
            self._state = .synced
        }
    }

    private func handleError(error: Error) {
        queue.async {
            self._state = .notSynced(error: error)
        }
    }

    private func _sync() {
        guard !_state.syncing else {
            return
        }

        _state = .syncing(progress: nil)

        Single.zip(_syncers.map { $0.transactionsSingle() })
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .subscribe(
                        onSuccess: { [weak self] resultArray in
                            self?.handleSuccess(resultArray: resultArray)
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

    var state: SyncState {
        queue.sync {
            _state
        }
    }

    func add(syncer: ITransactionSyncer) {
        queue.async {
            self._syncers.append(syncer)
        }
    }

    func sync() {
        queue.async {
            self._sync()
        }
    }

}
