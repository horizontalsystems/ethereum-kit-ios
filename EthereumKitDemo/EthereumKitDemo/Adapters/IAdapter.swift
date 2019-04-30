import EthereumKit
import RxSwift

protocol IAdapter {

    var name: String { get }
    var coin: String { get }

    var lastBlockHeight: Int? { get }
    var syncState: EthereumKit.SyncState { get }
    var balance: Decimal { get }

    var receiveAddress: String { get }

    var lastBlockHeightObservable: Observable<Void> { get }
    var syncStateObservable: Observable<Void> { get }
    var balanceObservable: Observable<Void> { get }
    var transactionsObservable: Observable<Void> { get }

    func validate(address: String) throws
    func sendSingle(to address: String, amount: Decimal) -> Single<Void>
    func transactionsSingle(from: (hash: String, interTransactionIndex: Int)?, limit: Int?) -> Single<[TransactionRecord]>

}
