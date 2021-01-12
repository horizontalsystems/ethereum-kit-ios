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

    private func doSync() -> Single<Void> {
        guard let pendingTransaction = storage.firstPendingTransaction() else {
            return Single.just(())
        }

        return blockchain.transactionReceiptSingle(transactionHash: pendingTransaction.hash)
                .flatMap { [weak self] receipt in
                    self?.syncTimestamp(transaction: pendingTransaction, receipt: receipt) ?? Single.just(())
                }
    }


    private func syncTimestamp(transaction: Transaction, receipt: RpcTransactionReceipt?) -> Single<Void> {
        guard let receipt = receipt else {
            return Single.just(())
        }

        return blockchain.getBlock(blockNumber: receipt.blockNumber)
                .flatMap { [weak self] block in
                    self?.handle(pendingTransaction: transaction, receipt: receipt, timestamp: block?.timestamp) ?? Single.just(())
                }
    }

    private func handle (pendingTransaction: Transaction, receipt: RpcTransactionReceipt, timestamp: Int?) -> Single<Void> {
        guard let timestamp = timestamp else {
            return Single.just(())
        }

        pendingTransaction.timestamp = timestamp

        storage.save(transaction: pendingTransaction)
        storage.save(transactionReceipt: TransactionReceipt(rpcReceipt: receipt))
        storage.save(logs: receipt.logs)

        listener?.onTransactionsSynced(fullTransactions: storage.fullTransactions(byHashes: [receipt.transactionHash]))

        return doSync()
    }

    override func onEthereumSynced() {
        sync()
    }

    override func onUpdateAccountState(accountState: AccountState) {
        sync()
    }

}
