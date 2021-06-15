import RxSwift
import BigInt

class EthereumTransactionSyncer: AbstractTransactionSyncer {
    private let provider: EtherscanTransactionProvider
    private let scheduler = ConcurrentDispatchQueueScheduler(qos: .background)

    init(provider: EtherscanTransactionProvider) {
        self.provider = provider

        super.init(id: "ethereum_transaction_syncer")
    }

    private func handle(transactions: [EtherscanTransaction]) {
        if !transactions.isEmpty {
            if let blockNumber = transactions.first?.blockNumber {
                update(lastSyncBlockNumber: blockNumber)
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

            delegate.add(notSyncedTransactions: notSyncedTransactions)
        }

        state = .synced
    }

    private func sync() {
        guard !state.syncing else {
            return
        }

        let single = provider.transactionsSingle(startBlock: lastSyncBlockNumber + 1)

        state = .syncing(progress: nil)

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

    override func onLastBlockNumber(blockNumber: Int) {
        sync()
    }

}
