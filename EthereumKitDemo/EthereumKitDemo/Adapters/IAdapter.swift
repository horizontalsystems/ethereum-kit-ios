import EthereumKit
import RxSwift

protocol IAdapter {

    var name: String { get }
    var coin: String { get }

    var lastBlockHeight: Int? { get }
    var syncState: EthereumKit.SyncState { get }
    var balance: Decimal { get }

    var receiveAddress: String { get }

    var lastBlockHeightSignal: Signal { get }
    var syncStateSignal: Signal { get }
    var balanceSignal: Signal { get }
    var transactionsSignal: Observable<Void> { get }

    func validate(address: String) throws
    func sendSingle(to address: String, amount: Decimal) -> Single<Void>
    func transactionsSingle(from: (hash: String, index: Int)?, limit: Int?) -> Single<[TransactionRecord]>

}
