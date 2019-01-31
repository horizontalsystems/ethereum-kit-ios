class Erc20Holder: IRefreshKitDelegate {

    var delegate: Erc20KitDelegate
    var balance: Decimal = 0
    var kitState: EthereumKit.KitState = .notSynced {
        didSet {
            delegate.kitStateUpdated(state: kitState)
        }
    }

    private let refreshTimer: IPeriodicTimer
    private let refreshManager: RefreshManager

    var refresh: (() -> ())?
    var disconnect: (() -> ())?

    init(delegate: Erc20KitDelegate, reachabilityManager: IReachabilityManager) {
        self.delegate = delegate

        refreshTimer = PeriodicTimer(interval: 30)
        refreshManager = RefreshManager(reachabilityManager: reachabilityManager, timer: refreshTimer)

        refreshManager.delegate = self
    }

    func didRefresh() {
        refreshManager.didRefresh()
    }

    func onRefresh() {
        refresh?()
    }

    func onDisconnect() {
        kitState = .notSynced

        disconnect?()
    }

}
