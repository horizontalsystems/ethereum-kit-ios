import RxSwift
import BigInt
import EthereumKit

class Erc20TransactionSyncer: AbstractTransactionSyncer {
    private let provider: EtherscanApiProvider
    private let contractAddress: Address
    private let scheduler = ConcurrentDispatchQueueScheduler(qos: .background)
    private var resync: Bool = false

    init(provider: EtherscanApiProvider, contractAddress: Address, id: String) {
        self.provider = provider
        self.contractAddress = contractAddress

        super.init(id: id)
    }

    private func doSync(retry: Bool) {
        let lastSyncBlockNumber = super.lastSyncBlockNumber
        var single = provider.tokenTransactionsSingle(contractAddress: contractAddress, startBlock: lastSyncBlockNumber + 1)

        if retry {
            single = single.retryWith(options: RetryOptions(mustRetry: { $0.isEmpty }), scheduler: scheduler)
        }

        single
                .observeOn(scheduler)
                .subscribe(
                        onSuccess: { [weak self] transactions in
                            guard let syncer = self else {
                                return
                            }

                            if !transactions.isEmpty {
                                var lastBlockNumber = lastSyncBlockNumber

                                let hashes = transactions.compactMap { data -> Data? in
                                    if let blockNumber = data["blockNumber"].flatMap { Int($0) }, blockNumber > lastBlockNumber {
                                        lastBlockNumber = blockNumber
                                    }

                                    return data["hash"].flatMap { Data(hex: $0) }
                                }

                                if lastBlockNumber > lastSyncBlockNumber {
                                    syncer.update(lastSyncBlockNumber: lastBlockNumber)
                                }

                                let notSyncedTransactions = hashes.map { hash in
                                    NotSyncedTransaction(hash: hash)
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

    override func onLastBlockBloomFilter(bloomFilter: BloomFilter) {
        if bloomFilter.mayContain(contractAddress: contractAddress) {
            sync(retry: true)
        }
    }

}
