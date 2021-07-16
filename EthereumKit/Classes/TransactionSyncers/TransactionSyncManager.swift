import RxSwift
import BigInt

class TransactionSyncManager {
    private let disposeBag = DisposeBag()
    private let scheduler = ConcurrentDispatchQueueScheduler(qos: .background)
    private let stateSubject = PublishSubject<SyncState>()
    private let transactionsSubject = PublishSubject<[FullTransaction]>()
    private let notSyncedTransactionManager: NotSyncedTransactionManager
    private let syncStateQueue = DispatchQueue(label: "transaction_sync_manager_state_queue", qos: .background)
    private let transactionsQueue = DispatchQueue(label: "transaction_sync_manager_transactions_queue", qos: .background)

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

    private func onUpdateAccountState(accountState: AccountState) {
        if self.accountState != nil {
            syncers.forEach {
                $0.onUpdateAccountState(accountState: accountState)
            }
        }

        self.accountState = accountState
    }

    private func syncState() {
        switch state {
        case .synced:
            if let notSyncedState = syncers.first(where: { $0.state.notSynced })?.state {
                state = notSyncedState
            }
        case .syncing, .notSynced:
            state = syncers.first { $0.state.notSynced }?.state ??
                    syncers.first { $0.state.syncing }?.state ??
                    .synced
        }
    }

    func add(syncer: ITransactionSyncer) {
        guard !syncers.contains(where: { $0.id == syncer.id }) else {
            return
        }

        syncer.set(delegate: notSyncedTransactionManager)

        syncers.append(syncer)
        syncerDisposables[syncer.id] = syncer.stateObservable
                .observeOn(scheduler)
                .subscribe(onNext: { [weak self] _ in
                    self?.syncStateQueue.async { [weak self] in
                        self?.syncState()
                    }
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
        transactionsQueue.async { [weak self] in
            self?.transactionsSubject.onNext(fullTransactions)
        }
    }

}
