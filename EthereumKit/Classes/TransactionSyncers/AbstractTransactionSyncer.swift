import RxSwift
import BigInt

open class AbstractTransactionSyncer: ITransactionSyncer {
    let stateSubject = PublishSubject<SyncState>()

    public let disposeBag = DisposeBag()
    public let id: String
    public var delegate: ITransactionSyncerDelegate!

    public var state: SyncState = .notSynced(error: Kit.SyncError.notStarted) {
        didSet {
            if state != oldValue {
                stateSubject.onNext(state)
            }
        }
    }

    public var stateObservable: Observable<SyncState> {
        stateSubject.asObservable()
    }

    public var lastSyncBlockNumber: Int {
        delegate.transactionSyncerState(id: id)?.lastBlockNumber ?? 0
    }

    public init(id: String) {
        self.id = id
    }

    public func set(delegate: ITransactionSyncerDelegate) {
        self.delegate = delegate
    }

    public func update(lastSyncBlockNumber: Int) {
        delegate.update(transactionSyncerState: TransactionSyncerState(id: id, lastBlockNumber: lastSyncBlockNumber))
    }

    open func start() {
    }

    open func onEthereumSynced() {
    }

    open func onLastBlockNumber(blockNumber: Int) {
    }

    open func onUpdateAccountState(accountState: AccountState) {
    }

}
