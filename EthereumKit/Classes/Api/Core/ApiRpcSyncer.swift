import RxSwift
import BigInt
import HsToolKit

class ApiRpcSyncer {
    weak var delegate: IRpcSyncerDelegate?

    private let address: Address
    private let rpcApiProvider: IRpcApiProvider
    private let reachabilityManager: IReachabilityManager

    private var isStarted = false

    private var disposeBag = DisposeBag()

    private(set) var syncState: SyncState = .notSynced(error: Kit.SyncError.notStarted) {
        didSet {
            if syncState != oldValue {
                delegate?.didUpdate(syncState: syncState)
            }
        }
    }

    init(address: Address, rpcApiProvider: IRpcApiProvider, reachabilityManager: IReachabilityManager) {
        self.address = address
        self.rpcApiProvider = rpcApiProvider
        self.reachabilityManager = reachabilityManager

        reachabilityManager.reachabilityObservable
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] _ in
                    self?.sync()
                })
                .disposed(by: disposeBag)
    }

    private func sync() {
        guard isStarted else {
            return
        }

        guard reachabilityManager.isReachable else {
            syncState = .notSynced(error: Kit.SyncError.noNetworkConnection)
            return
        }

        if case .syncing = syncState {
            return
        }

        syncState = .syncing(progress: nil)

        Single.zip(
                        rpcApiProvider.single(rpc: BlockNumberJsonRpc()),
                        rpcApiProvider.single(rpc: GetBalanceJsonRpc(address: address, defaultBlockParameter: .latest))
                )
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onSuccess: { [weak self] lastBlockHeight, balance in
                    self?.delegate?.didUpdate(lastBlockHeight: lastBlockHeight)
                    self?.delegate?.didUpdate(balance: balance)

                    self?.syncState = .synced
                }, onError: { [weak self] error in
                    self?.syncState = .notSynced(error: error)
                })
                .disposed(by: disposeBag)

    }

}

extension ApiRpcSyncer: IRpcSyncer {

    var source: String {
        "API \(rpcApiProvider.source)"
    }

    func start() {
        isStarted = true

        sync()
    }

    func stop() {
        isStarted = false

        disposeBag = DisposeBag()
        syncState = .notSynced(error: Kit.SyncError.notStarted)
    }

    func refresh() {
        sync()
    }

    func single<T>(rpc: JsonRpc<T>) -> Single<T> {
        rpcApiProvider.single(rpc: rpc)
    }

}
