import HSEthereumKit
import RxSwift

class Erc20Adapter: Erc20KitDelegate {
    private(set) var contractAddress: String = Manager.contractAddress
    private(set) var decimal: Int = Manager.contractDecimal

    let balanceSubject = PublishSubject<Decimal>()
    let lastBlockHeight = PublishSubject<Int>()
    let transactionsSubject = PublishSubject<Void>()
    let progressSubject = PublishSubject<EthereumKit.KitState>()

    public func transactionsUpdated(inserted: [EthereumTransaction], updated: [EthereumTransaction], deleted: [Int]) {
        transactionsSubject.onNext(())
    }

    public func balanceUpdated(balance: Decimal) {
        balanceSubject.onNext(balance)
    }

    public func lastBlockHeightUpdated(height: Int) {
        lastBlockHeight.onNext(height)
    }

    public func kitStateUpdated(state: EthereumKit.KitState) {
        progressSubject.onNext(state)
    }

}
