import RxSwift
import BigInt
import EthereumKit

protocol IBalanceManagerDelegate: AnyObject {
    func onSyncBalanceSuccess(balance: BigUInt)
    func onSyncBalanceFailed(error: Error)
}

protocol ITransactionManager {
    var transactionsObservable: Observable<[FullTransaction]> { get }

    func transactionsSingle(from: Data?, limit: Int?) -> Single<[FullTransaction]>
    func pendingTransactions() -> [FullTransaction]
    func transferTransactionData(to: Address, value: BigUInt) -> TransactionData
}

protocol IBalanceManager {
    var delegate: IBalanceManagerDelegate? { get set }

    var balance: BigUInt? { get }
    func sync()
}

protocol IDataProvider {
    func getBalance(contractAddress: Address, address: Address) -> Single<BigUInt>
}
