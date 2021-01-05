import RxSwift
import BigInt

class InternalTransactionSyncer: AbstractTransactionSyncer {
    private let ethereumTransactionProvider: EtherscanTransactionProvider
    private let storage: ITransactionStorage

    init(ethereumTransactionProvider: EtherscanTransactionProvider, storage: ITransactionStorage) {
        self.ethereumTransactionProvider = ethereumTransactionProvider
        self.storage = storage

        super.init(id: "internal_transaction_syncer")
    }

    private func sync() {
        print("syncing InternalTransactionProvider")
        guard !state.syncing else {
            return
        }

        print("InternalTransactionProvider syncing")
        state = .syncing(progress: nil)

        let lastSyncBlockNumber = super.lastSyncBlockNumber

        // gets transaction starting from last tx's block height
        ethereumTransactionProvider
                .internalTransactionsSingle(startBlock: lastSyncBlockNumber + 1)
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(
                        onSuccess: { [weak self] transactions in
                            print("InternalTransactionProvider got \(transactions.count) transactions")
                            guard let syncer = self else {
                                return
                            }

                            guard !transactions.isEmpty else {
                                syncer.state = .synced
                                return
                            }

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
                            syncer.state = .synced
                        },
                        onError: { [weak self] error in
                            self?.state = .notSynced(error: error)
                        }
                )
                .disposed(by: disposeBag)
    }

    override func onEthereumSynced() {
        sync()
    }

    override func onUpdateNonce(nonce: Int) {
        sync()
    }

    override func onUpdateBalance(balance: BigUInt) {
        sync()
    }

}