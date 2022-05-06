import RxSwift
import BigInt
import HsToolKit

class ApiRpcSyncer {
    weak var delegate: IRpcSyncerDelegate?

    private let rpcApiProvider: IRpcApiProvider
    private let reachabilityManager: IReachabilityManager
    private let syncInterval: TimeInterval
    private var disposeBag = DisposeBag()

    private var isStarted = false
    private var timer: Timer?

    private(set) var state: SyncerState = .notReady(error: Kit.SyncError.notStarted) {
        didSet {
            if state != oldValue {
                delegate?.didUpdate(state: state)
            }
        }
    }

    init(rpcApiProvider: IRpcApiProvider, reachabilityManager: IReachabilityManager, syncInterval: TimeInterval) {
        self.rpcApiProvider = rpcApiProvider
        self.reachabilityManager = reachabilityManager
        self.syncInterval = syncInterval

        reachabilityManager.reachabilityObservable
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .subscribe(onNext: { [weak self] reachable in
                    self?.handleUpdate(reachable: reachable)
                })
                .disposed(by: disposeBag)
    }

    deinit {
        stop()
    }

    @objc func onFireTimer() {
        rpcApiProvider.single(rpc: BlockNumberJsonRpc())
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .subscribe(onSuccess: { [weak self] lastBlockHeight in
                    self?.delegate?.didUpdate(lastBlockHeight: lastBlockHeight)
                })
                .disposed(by: disposeBag)
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { [weak self] _ in
            self?.onFireTimer()
        }
        timer?.tolerance = 0.5
    }

    private func handleUpdate(reachable: Bool) {
        guard isStarted else {
            return
        }

        if reachable {
            state = .ready

            DispatchQueue.main.async { [weak self] in
                self?.startTimer()
            }
        } else {
            state = .notReady(error: Kit.SyncError.noNetworkConnection)
            timer?.invalidate()
        }
    }

}

extension ApiRpcSyncer: IRpcSyncer {

    var source: String {
        "API \(rpcApiProvider.source)"
    }

    func start() {
        isStarted = true

        handleUpdate(reachable: reachabilityManager.isReachable)
    }

    func stop() {
        isStarted = false

        disposeBag = DisposeBag()
        state = .notReady(error: Kit.SyncError.notStarted)
        timer?.invalidate()
    }

    func single<T>(rpc: JsonRpc<T>) -> Single<T> {
        rpcApiProvider.single(rpc: rpc)
    }

}
