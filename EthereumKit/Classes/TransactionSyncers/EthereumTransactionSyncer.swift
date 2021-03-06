import RxSwift
import BigInt

class EthereumTransactionSyncer: AbstractTransactionSyncer {
    private let provider: EtherscanTransactionProvider
    private let scheduler = ConcurrentDispatchQueueScheduler(qos: .background)
    private var resync: Bool = false

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

        if resync {
            resync = false
            doSync(retry: true)
        } else {
            state = .synced
        }
    }

    private func doSync(retry: Bool) {
        var single = provider.transactionsSingle(startBlock: lastSyncBlockNumber + 1)

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
