import RxSwift

class OutgoingPendingTransactionSyncer {
    private let blockchain: IBlockchain
    private let storage: ITransactionStorage

    weak var listener: ITransactionSyncerListener?

    private let disposeBag = DisposeBag()
    private let stateSubject = PublishSubject<SyncState>()

    init(blockchain: IBlockchain, storage: ITransactionStorage) {
        self.blockchain = blockchain
        self.storage = storage
    }

    let id: String = "outgoing_pending_transaction_syncer"

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

    private func doSync() -> Single<Void> {
        print("OutputPendingTransactionSyncer doing sync")
        guard let pendingTransaction = storage.getFirstPendingTransaction() else {
            print("OutputPendingTransactionSyncer didn't find pending transaction")
            return Single.just(())
        }

        print("OutputPendingTransactionSyncer set syncing")

        return blockchain.transactionReceiptSingle(transactionHash: pendingTransaction.hash)
                .flatMap { [weak self] receipt in
                    print("OutputPendingTransactionSyncer got receipt")
                    guard let syncer = self, let receipt = receipt else {
                        return Single.just(())
                    }

                    syncer.storage.save(transactionReceipt: TransactionReceipt(rpcReceipt: receipt))
                    syncer.storage.save(logs: receipt.logs)

                    return syncer.doSync()
                }
    }

    private func sync() {
        print("OutgoingPendingTransactionSyncer sync \(state.syncing)")
        guard !state.syncing else {
            return
        }

        state = .syncing(progress: 0)

        doSync()
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe { [weak self] in
                    self?.state = .synced
                }
                .disposed(by: disposeBag)
    }

}

extension OutgoingPendingTransactionSyncer: ITransactionSyncer {

    func onEthereumSynced() {
        sync()
    }

    func onLastBlockNumber(blockNumber: Int) {
        sync()
    }

}
