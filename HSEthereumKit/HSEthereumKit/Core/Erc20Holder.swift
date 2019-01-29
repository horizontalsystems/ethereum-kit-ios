class Erc20Holder: IRefreshKitDelegate {
    let erc20: ERC20
    var balance: Decimal = 0

    private let refreshTimer: IPeriodicTimer
    private let refreshManager: RefreshManager

    var refresh: (() -> ())?
    var disconnect: (() -> ())?

    init(address: String, decimal: Int, reachabilityManager: IReachabilityManager) {
        erc20 = ERC20(contractAddress: address, decimal: decimal)

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
        disconnect?()
    }

}
