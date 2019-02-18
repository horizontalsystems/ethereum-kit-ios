import Foundation

class Erc20Holder {
    let delegate: Erc20KitDelegate

    var balance: Decimal {
        didSet {
            delegate.onUpdateBalance()
        }
    }

    var state: EthereumKit.SyncState = .notSynced {
        didSet {
            delegate.onUpdateState()
        }
    }

    init(delegate: Erc20KitDelegate, balance: Decimal) {
        self.delegate = delegate
        self.balance = balance
    }

}
