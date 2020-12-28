import RxSwift
import BigInt

class EthereumTransactionSyncer {
    private let ethereumTransactionProvider: ITransactionsProvider
    private let notSyncedTransactionPool: NotSyncedTransactionPool
    private let storage: ITransactionStorage
    private let disposeBag = DisposeBag()
    private let stateSubject = PublishSubject<SyncState>()

    private var lastSyncBlockNumber: Int

    let id: String = "ethereum_transaction_syncer"

    var state: SyncState = .notSynced(error: Kit.SyncError.notStarted) {
        didSet {
            if state != oldValue {
                stateSubject.onNext(state)
            }
        }
    }

    var stateObservable: Observable<SyncState> {
        stateSubject.asObservable()
    }

    init(ethereumTransactionProvider: ITransactionsProvider, notSyncedTransactionPool: NotSyncedTransactionPool, storage: ITransactionStorage) {
        self.ethereumTransactionProvider = ethereumTransactionProvider
        self.notSyncedTransactionPool = notSyncedTransactionPool
        self.storage = storage

        lastSyncBlockNumber = storage.transactionSyncerState(id: id)?.lastBlockNumber ?? 0
    }

    private func update(lastSyncBlockNumber: Int) {
        self.lastSyncBlockNumber = lastSyncBlockNumber
        storage.save(transactionSyncerState: TransactionSyncerState(id: id, lastBlockNumber: lastSyncBlockNumber))
    }

    private func sync() {
        print("syncing EthereumTransactionProvider")
        guard !state.syncing else {
            return
        }

        print("EthereumTransactionProvider syncing")
        state = .syncing(progress: 0)

        // gets transaction starting from last tx's block height
        ethereumTransactionProvider
                .transactionsSingle(startBlock: lastSyncBlockNumber + 1)
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(
                        onSuccess: { [weak self] txList in
                            print("EthereumTransactionProvider got \(txList.count) transactions")
                            if let blockNumber = txList.first?.blockNumber {
                                self?.update(lastSyncBlockNumber: blockNumber)
                            }

                            let notSyncedTransactions = txList.map { etherscanTransaction in
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

                            self?.notSyncedTransactionPool.add(notSyncedTransactions: notSyncedTransactions)
                            self?.state = .synced
                        },
                        onError: { [weak self] error in
                            self?.state = .notSynced(error: error)
                        }
                )
                .disposed(by: disposeBag)
    }

}

extension EthereumTransactionSyncer: ITransactionSyncer {

    func onEthereumSynced() {
        sync()
    }

    func onUpdateNonce(nonce: Int) {
        sync()
    }

    func onUpdateBalance(balance: BigUInt) {
        sync()
    }

}
