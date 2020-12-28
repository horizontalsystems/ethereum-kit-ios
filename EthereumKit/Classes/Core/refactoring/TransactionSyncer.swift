import RxSwift

protocol ITransactionSyncerListener: class {
    func onTransactionsSynced(fullTransactions: [FullTransaction])
}

class TransactionSyncer {
    private let pool: NotSyncedTransactionPool
    private let blockchain: IBlockchain
    private let storage: ITransactionStorage

    weak var listener: ITransactionSyncerListener?

    private let disposeBag = DisposeBag()
    private let stateSubject = PublishSubject<SyncState>()
    private let txSyncBatchSize = 10

    init(pool: NotSyncedTransactionPool, blockchain: IBlockchain, storage: ITransactionStorage) {
        self.pool = pool
        self.blockchain = blockchain
        self.storage = storage

        //subscribe to txHashPool and sync when new hashes received
        print("TransactionSyncer subscribing")
        pool.notSyncedTransactionsSignal
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onNext: { [weak self] in
                    print("TransactionSyncer running sync")
                    self?.sync()
                })
                .disposed(by: disposeBag)
    }

    let id: String = "transaction_syncer"

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

    private func sync() {
        print("TransactionSyncer sync \(state.syncing)")
        guard !state.syncing else {
            return
        }

        doSync()
    }

    private func doSync() {
        print("TransactionSyncer doing sync")
        let notSyncedTransactions = pool.getNotSyncedTransactions(limit: txSyncBatchSize)
        print("TransactionSyncer \(notSyncedTransactions.count) transactions")

        guard !notSyncedTransactions.isEmpty else {
            state = .synced
            return
        }

        print("TransactionSyncer set syncing")
        state = .syncing(progress: 0)

        Single
                .zip(notSyncedTransactions.map { syncSingle(notSyncedTransaction: $0) })
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(
                        onSuccess: { [weak self] syncedTransactionHashes in
                            guard let syncer = self else {
                                return
                            }
                            print("Synced transactions: \(syncedTransactionHashes)")
                            let hashes: [Data] = syncedTransactionHashes.compactMap { $0 }
                            let fullTransactions = syncer.storage.fullTransactions(byHashes: hashes)

                            syncer.listener?.onTransactionsSynced(fullTransactions: fullTransactions)
                            syncer.doSync()
                        },
                        onError: { [weak self] in
                            print("Error = \($0)")
                            self?.state = .notSynced(error: $0)
                        }
                )
                .disposed(by: disposeBag)
    }

    private func syncSingle(notSyncedTransaction: NotSyncedTransaction) -> Single<Data?> {
        syncRpcTransactionSingle(notSyncedTransaction: notSyncedTransaction)
                .flatMap { [weak self] transaction in
                    print("RpcTransaction received for \(notSyncedTransaction.hash.hex): \(transaction)")
                    guard let syncer = self,
                          let transaction = transaction else {
                        return Single.just(nil)
                    }

                    return syncer.syncReceiptSingle(transaction: transaction)
                }
                .flatMap { [weak self] (txReceiptPair: (transaction: RpcTransaction, receipt: RpcTransactionReceipt?)?) in
                    print("ReceiptPair received for \(notSyncedTransaction.hash.hex): \(txReceiptPair?.receipt)")
                    guard let syncer = self,
                          let txReceiptPair = txReceiptPair else {
                        return Single.just(nil)
                    }

                    return syncer.syncTimestampSingle(transactionAndReceipt: txReceiptPair, notSyncedTransaction: notSyncedTransaction)
                }
                .map { [weak self] (result: (transaction: RpcTransaction, timestamp: TimeInterval)?) in
                    print("Result received for \(notSyncedTransaction.hash.hex): \(result?.transaction) | \(result?.timestamp)")
                    guard let syncer = self,
                          let result = result else {
                        return nil
                    }

                    print("finalizing \(notSyncedTransaction.hash.hex)")
                    syncer.finalizeSync(notSyncedTransaction: notSyncedTransaction, transaction: result.transaction, timestamp: result.timestamp)

                    return result.transaction.hash
                }
    }

    private func finalizeSync(notSyncedTransaction: NotSyncedTransaction, transaction: RpcTransaction, timestamp: TimeInterval) {
        let transaction = Transaction(
                hash: transaction.hash,
                nonce: transaction.nonce,
                input: transaction.input,
                from: transaction.from,
                to: transaction.to,
                value: transaction.value,
                gasLimit: transaction.gasLimit,
                gasPrice: transaction.gasPrice,
                timestamp: timestamp
        )

        storage.save(transaction: transaction)
        pool.remove(notSyncedTransaction: notSyncedTransaction)
    }

    private func syncRpcTransactionSingle(notSyncedTransaction: NotSyncedTransaction) -> Single<RpcTransaction?> {
        if let transaction = notSyncedTransaction.transaction {
            return Single.just(transaction)
        }

        return blockchain.transactionSingle(transactionHash: notSyncedTransaction.hash)
                .do(onSuccess: { [weak self] transaction in
                    guard let transaction = transaction else {
                        return
                    }

                    notSyncedTransaction.transaction = transaction
                    self?.pool.update(notSyncedTransaction: notSyncedTransaction)
                })
    }

    private func syncReceiptSingle(transaction: RpcTransaction) -> Single<(transaction: RpcTransaction, receipt: RpcTransactionReceipt?)?> {
        if transaction.blockNumber == nil {
            return Single.just((transaction: transaction, receipt: nil))
        }

        if let transactionReceipt = storage.getTransactionReceipt(hash: transaction.hash) {
            return Single.just((transaction: transaction, receipt: RpcTransactionReceipt(record: transactionReceipt, logs: [])))
        }

        return blockchain.transactionReceiptSingle(transactionHash: transaction.hash)
                .do(onSuccess: { [weak self] receipt in
                    guard let syncer = self,
                          let receipt = receipt else {
                        return
                    }

                    syncer.storage.save(transactionReceipt: TransactionReceipt(rpcReceipt: receipt))
                    syncer.storage.save(logs: receipt.logs)
                })
                .map { rpcReceipt -> (transaction: RpcTransaction, receipt: RpcTransactionReceipt?)? in
                    rpcReceipt.map { (transaction: transaction, receipt: $0) }
                }
    }

    private func syncTimestampSingle(transactionAndReceipt: (transaction: RpcTransaction, receipt: RpcTransactionReceipt?), notSyncedTransaction: NotSyncedTransaction) -> Single<(transaction: RpcTransaction, timestamp: TimeInterval)?> {
        guard let receipt = transactionAndReceipt.receipt else {
            //pending
            return Single.just((transaction: transactionAndReceipt.transaction, timestamp: Date().timeIntervalSince1970))
        }

        if let timestamp = notSyncedTransaction.timestamp {
            return Single.just((transaction: transactionAndReceipt.transaction, timestamp: timestamp))
        }

        return blockchain.getBlock(blockNumber: receipt.blockNumber)
                .map { block -> (transaction: RpcTransaction, timestamp: TimeInterval)? in
                    block.map { (transaction: transactionAndReceipt.transaction, timestamp: $0.timestamp) }
                }
    }

}

extension TransactionSyncer: ITransactionSyncer {

    func onEthereumSynced() {
        sync()
    }

}
