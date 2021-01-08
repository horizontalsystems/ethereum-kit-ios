import RxSwift
import BigInt

class InternalTransactionSyncer: AbstractTransactionSyncer {
    private let provider: EtherscanTransactionProvider
    private let storage: ITransactionStorage
    private let scheduler = SerialDispatchQueueScheduler(qos: .background)
    private var resync: Bool = false

    init(provider: EtherscanTransactionProvider, storage: ITransactionStorage) {
        self.provider = provider
        self.storage = storage

        super.init(id: "internal_transaction_syncer")
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
                            print("InternalTransactionProvider got \(transactions.count) transactions")
                            guard let syncer = self else {
                                return
                            }

                            if !transactions.isEmpty {
                                syncer.storage.save(internalTransactions: transactions)

                                if let blockNumber = transactions.first?.blockNumber {
                                    syncer.update(lastSyncBlockNumber: blockNumber)
                                }

                                let notSyncedTransactions = transactions.map { etherscanTransaction in
                                    NotSyncedTransaction(
                                            hash: etherscanTransaction.hash
                                    )
                                }

                                syncer.delegate.add(notSyncedTransactions: notSyncedTransactions)
                            }

                            if syncer.resync {
                                syncer.resync = false
                                syncer.doSync(retry: true)
                            } else {
                                syncer.state = .synced
                            }
                        },
                        onError: { [weak self] error in
                            self?.state = .notSynced(error: error)
                        }
                )
                .disposed(by: disposeBag)
    }

    private func sync(retry: Bool = false) {
        print("syncing InternalTransactionProvider")
        if state.syncing {
            if retry {
                resync = true
            }
            return
        }

        print("InternalTransactionProvider syncing")
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