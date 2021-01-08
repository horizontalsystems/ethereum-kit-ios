import RxSwift
import BigInt
import EthereumKit

class Erc20TransactionSyncer: AbstractTransactionSyncer {
    private let provider: EtherscanApiProvider
    private let contractAddress: Address
    private let scheduler = SerialDispatchQueueScheduler(qos: .background)
    private var resync: Bool = false

    init(provider: EtherscanApiProvider, contractAddress: Address, id: String) {
        self.provider = provider
        self.contractAddress = contractAddress

        super.init(id: id)
    }

    private func sync(mayContain: Bool = false, force: Bool = false) {
        print("syncing Erc20TransactionSyncer")
        if state.syncing && !force {
            if mayContain {
                resync = true
            }
            return
        }

        print("Erc20TransactionSyncer syncing")
        state = .syncing(progress: nil)

        let lastSyncBlockNumber = super.lastSyncBlockNumber
        var single = provider.tokenTransactionsSingle(contractAddress: contractAddress, startBlock: lastSyncBlockNumber + 1)

        if mayContain {
            single = single.retryWith(options: RetryOptions(mustRetry: { $0.isEmpty }), scheduler: scheduler)
        }

        single
                .observeOn(scheduler)
                .subscribe(
                        onSuccess: { [weak self] transactions in
                            print("Erc20TransactionSyncer got \(transactions.count) transactions")

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

    override func onLastBlockBloomFilter(bloomFilter: BloomFilter) {
        if bloomFilter.mayContain(contractAddress: contractAddress) {
            sync()
        }
    }

}
