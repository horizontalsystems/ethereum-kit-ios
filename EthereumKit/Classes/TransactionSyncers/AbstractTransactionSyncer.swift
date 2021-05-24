import RxSwift
import BigInt

open class AbstractTransactionSyncer: ITransactionSyncer {
    let stateSubject = PublishSubject<SyncState>()

    public let disposeBag = DisposeBag()
    public let id: String
    public var delegate: ITransactionSyncerDelegate!
    private let stateQueue = DispatchQueue(label: "transaction_syncer_state_queue", qos: .background)

    public var state: SyncState = .notSynced(error: Kit.SyncError.notStarted) {
        didSet {
            if state != oldValue {
                stateQueue.async { [weak self] in
                    self.map { $0.stateSubject.onNext($0.state) }
                }
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
