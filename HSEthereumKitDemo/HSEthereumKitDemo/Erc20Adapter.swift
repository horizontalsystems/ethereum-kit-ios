import HSEthereumKit
import RxSwift

class Erc20Adapter: IEthereumKitDelegate {
    let balanceSubject = PublishSubject<Void>()
    let lastBlockHeight = PublishSubject<Void>()
    let transactionsSubject = PublishSubject<Void>()
    let syncStateSubject = PublishSubject<Void>()

    func onUpdate(transactions: [EthereumTransaction]) {
        transactionsSubject.onNext(())
    }

    func onUpdateBalance() {
        balanceSubject.onNext(())
    }

    func onUpdateLastBlockHeight() {
        lastBlockHeight.onNext(())
    }

    func onUpdateSyncState() {
        syncStateSubject.onNext(())
    }

}
