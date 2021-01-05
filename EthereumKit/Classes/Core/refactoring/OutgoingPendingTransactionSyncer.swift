import RxSwift

class OutgoingPendingTransactionSyncer: AbstractTransactionSyncer {
    private let blockchain: IBlockchain
    private let storage: ITransactionStorage

    weak var listener: ITransactionSyncerListener?

    init(blockchain: IBlockchain, storage: ITransactionStorage) {
        self.blockchain = blockchain
        self.storage = storage

        super.init(id: "outgoing_pending_transaction_syncer")
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

                    syncer.listener?.onTransactionsSynced(fullTransactions: syncer.storage.fullTransactions(byHashes: [receipt.transactionHash]))

                    return syncer.doSync()
                }
    }

    private func sync() {
        print("OutgoingPendingTransactionSyncer sync \(state.syncing)")
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

    override func onEthereumSynced() {
        sync()
    }

    override func onLastBlockNumber(blockNumber: Int) {
        sync()
    }

}
