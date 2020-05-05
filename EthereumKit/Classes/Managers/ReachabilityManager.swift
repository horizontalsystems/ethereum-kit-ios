import Alamofire
import RxSwift

class ReachabilityManager {
    private let manager: NetworkReachabilityManager?

    private(set) var isReachable: Bool
    let reachabilitySignal = Signal()

    init() {
        manager = NetworkReachabilityManager()

        isReachable = manager?.isReachable ?? false

        manager?.startListening { [weak self] _ in
            self?.onUpdateStatus()
        }
    }

    private func onUpdateStatus() {
        let newReachable = manager?.isReachable ?? false

        if isReachable != newReachable {
            isReachable = newReachable
            reachabilitySignal.notify()
        }
    }

}

extension ReachabilityManager: IReachabilityManager {
}
