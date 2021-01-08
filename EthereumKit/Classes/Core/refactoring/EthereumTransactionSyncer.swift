import RxSwift
import BigInt

class EthereumTransactionSyncer: AbstractTransactionSyncer {
    private let provider: EtherscanTransactionProvider
    private let scheduler = SerialDispatchQueueScheduler(qos: .background)
    private var resync: Bool = false

    init(provider: EtherscanTransactionProvider) {
        self.provider = provider

        super.init(id: "ethereum_transaction_syncer")
    }

    private func sync(mayContain: Bool = false, force: Bool = false) {
        print("syncing EthereumTransactionProvider")
        if state.syncing && !force {
            if mayContain {
                resync = true
            }
            return
        }

        print("EthereumTransactionProvider syncing")
        state = .syncing(progress: nil)

        var single = provider.transactionsSingle(startBlock: lastSyncBlockNumber + 1)

        if mayContain {
            single = single.retryWith(options: RetryOptions(mustRetry: { $0.isEmpty }), scheduler: scheduler)
        }

        single
                .observeOn(scheduler)
                .subscribe(
                        onSuccess: { [weak self] transactions in
                            print("EthereumTransactionProvider got \(transactions.count) transactions")
                            guard let syncer = self else {
                                return
                            }

                            if !transactions.isEmpty {
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
                            }

                            if syncer.resync {
                                syncer.resync = false
                                syncer.sync(mayContain: true, force: true)
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

    override func onEthereumSynced() {
        sync()
    }

    override func onUpdateAccountState(accountState: AccountState) {
        sync(mayContain: true)
    }

}
