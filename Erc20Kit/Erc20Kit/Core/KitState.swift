import BigInt
import RxSwift

class KitState {
    var syncState: Erc20Kit.SyncState = .syncing {
        didSet {
            if syncState != oldValue {
                syncStateSubject.onNext(syncState)
            }
        }
    }

    var balance: BigUInt? {
        didSet {
            if let balance = balance, balance != oldValue {
                balanceSubject.onNext(balance.description)
            }
        }
    }

    let syncStateSubject = PublishSubject<Erc20Kit.SyncState>()
    let balanceSubject = PublishSubject<String>()
    let transactionsSubject = PublishSubject<[TransactionInfo]>()
}
