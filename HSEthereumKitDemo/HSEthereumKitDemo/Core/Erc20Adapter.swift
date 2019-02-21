import HSEthereumKit
import RxSwift

class Erc20Adapter: BaseAdapter {
    let contractAddress: String

    init(ethereumKit: EthereumKit, contractAddress: String, decimal: Int) {
        self.contractAddress = EIP55.format(contractAddress)

        super.init(ethereumKit: ethereumKit, decimal: decimal)

        ethereumKit.register(contractAddress: contractAddress, delegate: self)
    }

    override var syncState: EthereumKit.SyncState {
        return ethereumKit.syncStateErc20(contractAddress: contractAddress)
    }

    override var balanceString: String? {
        return ethereumKit.balanceErc20(contractAddress: contractAddress)
    }

    override func sendSingle(to address: String, amount: String) -> Single<Void> {
        return ethereumKit.sendErc20Single(to: address, contractAddress: contractAddress, amount: amount).map { _ in ()}
    }

    override func transactionsObservable(hashFrom: String? = nil, limit: Int? = nil) -> Single<[EthereumTransaction]> {
        return ethereumKit.transactionsErc20Single(contractAddress: contractAddress, fromHash: hashFrom, limit: limit)
    }

}

extension Erc20Adapter: IEthereumKitDelegate {
}
