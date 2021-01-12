import RxSwift
import BigInt

class InternalTransactionSyncer: AbstractTransactionSyncer {
    private let provider: EtherscanTransactionProvider
    private let storage: ITransactionStorage
    private let scheduler = ConcurrentDispatchQueueScheduler(qos: .background)
    private var resync: Bool = false

    weak var listener: ITransactionSyncerListener?

    init(provider: EtherscanTransactionProvider, storage: ITransactionStorage) {
        self.provider = provider
        self.storage = storage

        super.init(id: "internal_transaction_syncer")
    }

    private func handle(transactions: [InternalTransaction]) {
        if !transactions.isEmpty {
            storage.save(internalTransactions: transactions)

            if let blockNumber = transactions.first?.blockNumber {
                update(lastSyncBlockNumber: blockNumber)
            }

            var notSyncedTransactions = [NotSyncedTransaction]()
            var syncedTransactions = [FullTransaction]()

            for etherscanTransaction in transactions {
                if let transaction = storage.transaction(hash: etherscanTransaction.hash) {
                    syncedTransactions.append(transaction)
                } else {
                    notSyncedTransactions.append(NotSyncedTransaction(hash: etherscanTransaction.hash))
                }
            }

            if !notSyncedTransactions.isEmpty {
                delegate.add(notSyncedTransactions: notSyncedTransactions)
            }

            if !syncedTransactions.isEmpty {
                listener?.onTransactionsSynced(fullTransactions: syncedTransactions)
            }
        }

        if resync {
            resync = false
            doSync(retry: true)
        } else {
            state = .synced
        }
    }

    private func doSync(retry: Bool) {
        var single = provider.internalTransactionsSingle(startBlock: lastSyncBlockNumber + 1)

        if retry {
            single = single.retryWith(options: RetryOptions(mustRetry: { $0.isEmpty }), scheduler: scheduler)
        }

        single
                .observeOn(scheduler)
                .subscribe(
                        onSuccess: { [weak self] transactions in
                            self?.handle(transactions: transactions)
                        },
                        onError: { [weak self] error in
                            self?.state = .notSynced(error: error)
                        }
                )
                .disposed(by: disposeBag)
    }

    private func sync(retry: Bool = false) {
        if state.syncing {
            if retry {
                resync = true
            }
            return
        }

        state = .syncing(progress: nil)
        doSync(retry: retry)
    }

    override func onEthereumSynced() {
        sync()
    }

    override func onUpdateAccountState(accountState: AccountState) {
        sync(retry: true)
    }

}