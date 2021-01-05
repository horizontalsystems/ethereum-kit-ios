import RxSwift
import BigInt

class TransactionSyncManager {
    private let disposeBag = DisposeBag()
    private let scheduler = ConcurrentDispatchQueueScheduler(qos: .background)
    private let stateSubject = PublishSubject<SyncState>()
    private let transactionsSubject = PublishSubject<[FullTransaction]>()
    private let notSyncedTransactionManager: NotSyncedTransactionManager

    private var syncers = [ITransactionSyncer]()
    private var syncerDisposables = [String: Disposable]()

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

    var transactionsObservable: Observable<[FullTransaction]> {
        transactionsSubject.asObservable()
    }

    init(notSyncedTransactionManager: NotSyncedTransactionManager) {
        self.notSyncedTransactionManager = notSyncedTransactionManager
    }

    func set(ethereumKit: EthereumKit.Kit) {
        ethereumKit.balanceObservable
                .observeOn(scheduler)
                .subscribe(onNext: { [weak self] in
                    self?.onUpdateBalance(balance: $0)
                })
                .disposed(by: disposeBag)

        ethereumKit.nonceObservable
                .observeOn(scheduler)
                .subscribe(onNext: { [weak self] in
                    self?.onUpdateNonce(nonce: $0)
                })
                .disposed(by: disposeBag)

        ethereumKit.lastBlockHeightObservable
                .observeOn(scheduler)
                .subscribe(onNext: { [weak self] in
                    self?.onLastBlockNumber(blockNumber: $0)
                })
                .disposed(by: disposeBag)

        ethereumKit.lastBlockBloomFilterObservable
                .observeOn(scheduler)
                .subscribe(onNext: { [weak self] in
                    self?.onLastBlockBloomFilter(bloomFilter: $0)
                })
                .disposed(by: disposeBag)

        ethereumKit.syncStateObservable
                .observeOn(scheduler)
                .subscribe(onNext: { [weak self] in
                    self?.onEthereumKitSyncState(state: $0)
                })
                .disposed(by: disposeBag)
    }

    private func onEthereumKitSyncState(state: SyncState) {
        if .synced == state {
            syncers.forEach { $0.onEthereumSynced() }
        }
    }

    private func onLastBlockNumber(blockNumber: Int) {
        syncers.forEach { $0.onLastBlockNumber(blockNumber: blockNumber) }
    }

    private func onLastBlockBloomFilter(bloomFilter: BloomFilter) {
        syncers.forEach { $0.onLastBlockBloomFilter(bloomFilter: bloomFilter) }
    }

    private func onUpdateNonce(nonce: Int) {
        syncers.forEach { $0.onUpdateNonce(nonce: nonce)}
    }

    private func onUpdateBalance(balance: BigUInt) {
        syncers.forEach { $0.onUpdateBalance(balance: balance)}
    }

    private func syncState() {
        print("syncer states: \(syncers.map { "\($0.id) -> \($0.state)" })")
        state = syncers.first { $0.state.notSynced }?.state ??
                syncers.first { $0.state.syncing }?.state ??
                .synced
    }

    func add(syncer: ITransactionSyncer) {
        syncer.set(delegate: notSyncedTransactionManager)

        syncers.append(syncer)
        syncerDisposables[syncer.id] = syncer.stateObservable
                .observeOn(scheduler)
                .subscribe(onNext: { [weak self] _ in
                    self?.syncState()
                })

        syncState()
    }

    func removeSyncer(byId id: String) {
        syncers.removeAll { $0.id == id }
        syncerDisposables[id]?.dispose()
        syncerDisposables.removeValue(forKey: id)
    }

}

extension TransactionSyncManager: ITransactionSyncerListener {

    func onTransactionsSynced(fullTransactions: [FullTransaction]) {
        transactionsSubject.onNext(fullTransactions)
    }

}
