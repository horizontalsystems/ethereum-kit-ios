import RxSwift
import BigInt
import HsToolKit

class ApiSyncer {
    weak var delegate: IRpcSyncerDelegate?

    private let address: Address
    private let rpcApiProvider: IRpcApiProvider

    private var disposeBag = DisposeBag()

    private(set) var syncState: SyncState = .notSynced(error: Kit.SyncError.notStarted) {
        didSet {
            if syncState != oldValue {
                delegate?.didUpdate(syncState: syncState)
            }
        }
    }

    init(address: Address, rpcApiProvider: IRpcApiProvider) {
        self.address = address
        self.rpcApiProvider = rpcApiProvider
    }

    private func sync() {
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

extension ApiSyncer: IRpcSyncer {

    var source: String {
        "API \(rpcApiProvider.source)"
    }

    func start() {
        sync()
    }

    func stop(error: Error) {
        disposeBag = DisposeBag()
        syncState = .notSynced(error: error)
    }

    func refresh() {
        sync()
    }

    func single<T>(rpc: JsonRpc<T>) -> Single<T> {
        rpcApiProvider.single(rpc: rpc)
    }

}
