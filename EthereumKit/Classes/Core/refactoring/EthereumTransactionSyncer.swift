import RxSwift
import BigInt

class EthereumTransactionSyncer: AbstractTransactionSyncer {
    private let ethereumTransactionProvider: EtherscanTransactionProvider

    init(ethereumTransactionProvider: EtherscanTransactionProvider) {
        self.ethereumTransactionProvider = ethereumTransactionProvider

        super.init(id: "ethereum_transaction_syncer")
    }

    private func sync() {
        print("syncing EthereumTransactionProvider")
        guard !state.syncing else {
            return
        }

        print("EthereumTransactionProvider syncing")
        state = .syncing(progress: nil)

        let lastSyncBlockNumber = super.lastSyncBlockNumber

        // gets transaction starting from last tx's block height
        ethereumTransactionProvider
                .transactionsSingle(startBlock: lastSyncBlockNumber + 1)
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(
                        onSuccess: { [weak self] transactions in
                            print("EthereumTransactionProvider got \(transactions.count) transactions")
                            guard let syncer = self else {
                                return
                            }

                            guard !transactions.isEmpty else {
                                syncer.state = .synced
                                return
                            }

                            if let blockNumber = transactions.first?.blockNumber {
                                syncer.update(lastSyncBlockNumber: blockNumber)
                            }

                            let notSyncedTransactions = transactions.map { etherscanTransaction in
                                NotSyncedTransaction(
                                        hash: etherscanTransaction.hash,
                                        transaction: RpcTransaction(
                                                hash: etherscanTransaction.hash,
                                                nonce: etherscanTransaction.nonce,
                                                from: etherscanTransaction.from,
                                                to: etherscanTransaction.to,
                                                value: etherscanTransaction.value,
                                                gasPrice: etherscanTransaction.gasPrice,
                                                gasLimit: etherscanTransaction.gasLimit,
                                                input: etherscanTransaction.input,
                                                blockHash: etherscanTransaction.blockHash,
                                                blockNumber: etherscanTransaction.blockNumber,
                                                transactionIndex: etherscanTransaction.transactionIndex
                                        ),
                                        timestamp: etherscanTransaction.timestamp
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
