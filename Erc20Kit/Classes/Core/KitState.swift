import BigInt
import RxSwift
import EthereumKit

class KitState {
    var syncState: Erc20Kit.SyncState = .syncing {
        didSet {
            if syncState != oldValue {
                syncStateSubject.onNext(syncState)
            }
        }
    }

    var transactionsSyncState: Erc20Kit.SyncState = .notSynced(error: EthereumKit.Kit.SyncError.notStarted) {
        didSet {
            if syncState != oldValue {
                transactionsSyncStateSubject.onNext(syncState)
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

    let syncStateSubject = PublishSubject<Erc20Kit.SyncState>()
    let transactionsSyncStateSubject = PublishSubject<Erc20Kit.SyncState>()
    let balanceSubject = PublishSubject<BigUInt>()
    let transactionsSubject = PublishSubject<[Transaction]>()
}
