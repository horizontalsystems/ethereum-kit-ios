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
    private var accountState: AccountState? = nil

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
        accountState = ethereumKit.accountState

        ethereumKit.accountStateObservable
                .observeOn(scheduler)
                .subscribe(onNext: { [weak self] in
                    self?.onUpdateAccountState(accountState: $0)
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

    private func onUpdateAccountState(accountState: AccountState) {
        if self.accountState != nil {
            syncers.forEach {
                $0.onUpdateAccountState(accountState: accountState)
            }
        }

        self.accountState = accountState
    }

    private func syncState() {
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

        syncer.start()
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
