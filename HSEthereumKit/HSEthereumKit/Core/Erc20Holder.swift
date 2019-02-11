class Erc20Holder {

    var delegate: Erc20KitDelegate
    var balance: Decimal = 0
    var kitState: EthereumKit.KitState = .notSynced {
        didSet {
            delegate.kitStateUpdated(state: kitState)
        }
    }

    init(delegate: Erc20KitDelegate) {
        self.delegate = delegate
    }

}
