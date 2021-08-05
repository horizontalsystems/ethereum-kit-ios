import RxSwift

class PendingTransactionSyncer: AbstractTransactionSyncer {
    private let blockchain: IBlockchain
    private let storage: ITransactionStorage

    weak var listener: ITransactionSyncerListener?

    init(blockchain: IBlockchain, storage: ITransactionStorage) {
        self.blockchain = blockchain
        self.storage = storage

        super.init(id: "outgoing_pending_transaction_syncer")
    }

    private func sync() {
        guard !state.syncing else {
            return
        }

        state = .syncing(progress: nil)

        doSync()
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe { [weak self] in
                    self?.state = .synced
                }
                .disposed(by: disposeBag)
    }

    private func doSync(fromTransaction: Transaction? = nil) -> Single<Void> {
        let pendingTransactions = storage.pendingTransactions(fromTransaction: fromTransaction)
        let notReplacedPendingTransactions = replaceDuplicateTransactions(pendingTransactions: pendingTransactions)

        guard !notReplacedPendingTransactions.isEmpty else {
            return Single.just(())
        }

        let singles = notReplacedPendingTransactions.map { pendingTransaction in
            blockchain.transactionReceiptSingle(transactionHash: pendingTransaction.hash)
                    .flatMap { [weak self] receipt in
                        self?.syncTimestamp(transaction: pendingTransaction, receipt: receipt) ?? Single.just(())
                    }
        }

        return Single.zip(singles)
                .flatMap { [weak self] _ in
                    self?.doSync(fromTransaction: pendingTransactions.last) ?? Single.just(())
                }
    }

    private func replaceDuplicateTransactions(pendingTransactions: [Transaction]) -> [Transaction] {
        var notReplaced = [Transaction]()

        for transaction in pendingTransactions {
            if let duplicatedTransaction = storage.transactionInBlock(nonce: transaction.nonce) {
                storage.add(droppedTransaction: DroppedTransaction(hash: transaction.hash, replacedWith: duplicatedTransaction.hash))
                listener?.onTransactionsSynced(fullTransactions: storage.fullTransactions(byHashes: [transaction.hash]))
            } else {
                notReplaced.append(transaction)
            }
        }

        return notReplaced
    }

    private func syncTimestamp(transaction: Transaction, receipt: RpcTransactionReceipt?) -> Single<Void> {
        guard let receipt = receipt else {
            return Single.just(())
        }

        return blockchain.getBlock(blockNumber: receipt.blockNumber)
                .do(onSuccess: { [weak self] block in
                    self?.handle(pendingTransaction: transaction, receipt: receipt, timestamp: block?.timestamp)
                })
                .map { _ in }
    }

    private func handle(pendingTransaction: Transaction, receipt: RpcTransactionReceipt, timestamp: Int?) {
        guard let timestamp = timestamp else {
            return
        }

        pendingTransaction.timestamp = timestamp

        storage.save(transaction: pendingTransaction)
        storage.save(transactionReceipt: TransactionReceipt(rpcReceipt: receipt))
        storage.save(logs: receipt.logs)

        listener?.onTransactionsSynced(fullTransactions: storage.fullTransactions(byHashes: [receipt.transactionHash]))
    }

    override func onLastBlockNumber(blockNumber: Int) {
        sync()
    }

}
