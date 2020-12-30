import RxSwift
import BigInt

class InternalTransactionSyncer {
    private let ethereumTransactionProvider: ITransactionsProvider
    private let notSyncedTransactionPool: NotSyncedTransactionPool
    private let storage: ITransactionStorage
    private let disposeBag = DisposeBag()
    private let stateSubject = PublishSubject<SyncState>()

    private var lastSyncBlockNumber: Int

    let id: String = "internal_transaction_syncer"

    var state: SyncState = .notSynced(error: Kit.SyncError.notStarted) {
        didSet {
            if state != oldValue {
                stateSubject.onNext(state)
            }
        }
    }

    var stateObservable: Observable<SyncState> {
        stateSubject.asObservable()
    }

    init(ethereumTransactionProvider: ITransactionsProvider, notSyncedTransactionPool: NotSyncedTransactionPool, storage: ITransactionStorage) {
        self.ethereumTransactionProvider = ethereumTransactionProvider
        self.notSyncedTransactionPool = notSyncedTransactionPool
        self.storage = storage

        lastSyncBlockNumber = storage.transactionSyncerState(id: id)?.lastBlockNumber ?? 0
    }

    private func update(lastSyncBlockNumber: Int) {
        self.lastSyncBlockNumber = lastSyncBlockNumber
        storage.save(transactionSyncerState: TransactionSyncerState(id: id, lastBlockNumber: lastSyncBlockNumber))
    }

    private func sync() {
        print("syncing InternalTransactionProvider")
        guard !state.syncing else {
            return
        }

        print("InternalTransactionProvider syncing")
        state = .syncing(progress: nil)

        // gets transaction starting from last tx's block height
        ethereumTransactionProvider
                .internalTransactionsSingle(startBlock: lastSyncBlockNumber + 1)
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(
                        onSuccess: { [weak self] txList in
                            print("InternalTransactionProvider got \(txList.count) transactions")
                            if let blockNumber = txList.first?.blockNumber {
                                self?.update(lastSyncBlockNumber: blockNumber)
                            }

                            let notSyncedTransactions = txList.map { etherscanTransaction in
                                NotSyncedTransaction(
                                        hash: etherscanTransaction.hash
                                )
                            }

                            self?.notSyncedTransactionPool.add(notSyncedTransactions: notSyncedTransactions)
                            self?.state = .synced
                        },
                        onError: { [weak self] error in
                            self?.state = .notSynced(error: error)
                        }
                )
                .disposed(by: disposeBag)
    }

}

extension InternalTransactionSyncer: ITransactionSyncer {

    func onEthereumSynced() {
        sync()
    }

    func onUpdateNonce(nonce: Int) {
        sync()
    }

    func onUpdateBalance(balance: BigUInt) {
        sync()
    }

}