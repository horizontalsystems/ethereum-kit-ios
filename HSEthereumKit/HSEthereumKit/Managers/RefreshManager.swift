import Foundation
import RxSwift

class RefreshManager {

    private let disposeBag = DisposeBag()

    private var timer: IPeriodicTimer
    public weak var delegate: IRefreshKitDelegate?

    init(delegate: IRefreshKitDelegate? = nil, reachabilityManager: IReachabilityManager, timer: IPeriodicTimer) {
        self.delegate = delegate
        self.timer = timer

        self.timer.delegate = self

        reachabilityManager.subject
                .subscribe(onNext: { [weak self] connected in
                    if connected {
                        self?.refresh()
                    } else {
                        self?.disconnect()
                    }
                })
                .disposed(by: disposeBag)
    }

    private func refresh() {
        delegate?.onRefresh()
    }

    private func disconnect() {
        delegate?.onDisconnect()
        timer.invalidate()
    }

}

extension RefreshManager: IPeriodicTimerDelegate {

    func onFire() {
        refresh()
    }

}

extension RefreshManager: IRefreshManager {

    func didRefresh() {
        timer.schedule()
    }

}
