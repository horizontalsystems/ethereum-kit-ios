import HSEthereumKit
import RxSwift

class Erc20Adapter: Erc20KitDelegate {
    private(set) var contractAddress: String = Manager.contractAddress
    private(set) var decimal: Int = Manager.contractDecimal

    let balanceSubject = PublishSubject<Void>()
    let lastBlockHeight = PublishSubject<Void>()
    let transactionsSubject = PublishSubject<Void>()
    let stateSubject = PublishSubject<Void>()

    func onUpdate(transactions: [EthereumTransaction]) {
        transactionsSubject.onNext(())
    }

    func onUpdateBalance() {
        balanceSubject.onNext(())
    }

    func onUpdateLastBlockHeight() {
        lastBlockHeight.onNext(())
    }

    func onUpdateState() {
        stateSubject.onNext(())
    }

}
