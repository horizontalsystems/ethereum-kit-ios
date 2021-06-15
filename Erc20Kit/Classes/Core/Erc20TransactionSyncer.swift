import RxSwift
import BigInt
import EthereumKit

class Erc20TransactionSyncer: AbstractTransactionSyncer {
    private let provider: EtherscanService
    private let scheduler = ConcurrentDispatchQueueScheduler(qos: .background)

    init(provider: EtherscanService) {
        self.provider = provider

        super.init(id: "erc20_transaction_syncer")
    }

    private func handle(transactions: [[String: String]]) {
        if !transactions.isEmpty {
            var lastBlockNumber = lastSyncBlockNumber

            let hashes = transactions.compactMap { data -> Data? in
                if let blockNumber = data["blockNumber"].flatMap({ Int($0) }), blockNumber > lastBlockNumber {
                    lastBlockNumber = blockNumber
                }

                return data["hash"].flatMap { Data(hex: $0) }
            }

            if lastBlockNumber > lastSyncBlockNumber {
                update(lastSyncBlockNumber: lastBlockNumber)
            }

            let notSyncedTransactions = hashes.map { hash in
                NotSyncedTransaction(hash: hash)
            }

            delegate.add(notSyncedTransactions: notSyncedTransactions)
        }

        state = .synced
    }

    private func sync() {
        guard !state.syncing else {
            return
        }

        let single = provider.tokenTransactionsSingle(startBlock: super.lastSyncBlockNumber + 1)

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

    override func start() {
        sync()
    }

    override func onLastBlockNumber(blockNumber: Int) {
        sync()
    }

}
