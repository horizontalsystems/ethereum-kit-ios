import BigInt
import RxSwift
import EthereumKit

class KitState {
    var syncState: SyncState = .syncing(progress: nil) {
        didSet {
            if syncState != oldValue {
                syncStateSubject.onNext(syncState)
            }
        }
    }

    var balance: BigUInt? {
        didSet {
            if let balance = balance, balance != oldValue {
                balanceSubject.onNext(balance)
            }
        }
    }

    let syncStateSubject = PublishSubject<SyncState>()
    let balanceSubject = PublishSubject<BigUInt>()
}
