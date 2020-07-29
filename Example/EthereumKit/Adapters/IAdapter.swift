import EthereumKit
import RxSwift

protocol IAdapter {
    func refresh()

    var name: String { get }
    var coin: String { get }

    var lastBlockHeight: Int? { get }
    var syncState: SyncState { get }
    var transactionsSyncState: SyncState { get }
    var balance: Decimal { get }

    var receiveAddress: Address { get }

    var lastBlockHeightObservable: Observable<Void> { get }
    var syncStateObservable: Observable<Void> { get }
    var transactionsSyncStateObservable: Observable<Void> { get }
    var balanceObservable: Observable<Void> { get }
    var transactionsObservable: Observable<Void> { get }

    func sendSingle(to address: Address, amount: Decimal, gasLimit: Int) -> Single<Void>
    func transactionsSingle(from: (hash: Data, interTransactionIndex: Int)?, limit: Int?) -> Single<[TransactionRecord]>
    func transaction(hash: Data, interTransactionIndex: Int) -> TransactionRecord?

    func estimatedGasLimit(to address: Address, value: Decimal) -> Single<Int>
}
