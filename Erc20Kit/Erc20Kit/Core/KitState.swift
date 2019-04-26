import EthereumKit
import RxSwift

class KitState {
    let contractAddress: Data = Data()

    var syncState: Erc20Kit.SyncState = .syncing {
        didSet {
            if syncState != oldValue {
                syncStateSubject.onNext(syncState)
            }
        }
    }

    var balance: BInt? {
        didSet {
            if let balance = balance, balance != oldValue {
                balanceSubject.onNext(balance.asString(withBase: 10))
            }
        }
    }

    let syncStateSubject = PublishSubject<Erc20Kit.SyncState>()
    let balanceSubject = PublishSubject<String>()
    let transactionsSubject = PublishSubject<[TransactionInfo]>()
}
