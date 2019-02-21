import HSEthereumKit
import RxSwift

class EthereumAdapter: BaseAdapter {

    init(ethereumKit: EthereumKit) {
        super.init(ethereumKit: ethereumKit, decimal: 18)

        ethereumKit.delegate = self
    }

    override var syncState: EthereumKit.SyncState {
        return ethereumKit.syncState
    }

    override var balanceString: String? {
        return ethereumKit.balance
    }

    override func sendSingle(to address: String, amount: String) -> Single<Void> {
        return ethereumKit.sendSingle(to: address, amount: amount).map { _ in ()}
    }

    override func transactionsObservable(hashFrom: String? = nil, limit: Int? = nil) -> Single<[EthereumTransaction]> {
        return ethereumKit.transactionsSingle(fromHash: hashFrom, limit: limit)
    }

}

extension EthereumAdapter: IEthereumKitDelegate {
}
