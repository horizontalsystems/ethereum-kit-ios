import Foundation
import RxSwift

protocol IReachabilityManager {
    var subject: PublishSubject<Bool> { get set }
    func reachable() -> Bool
}

protocol IApiConfigProvider {
    var reachabilityHost: String { get }
    var apiUrl: String { get }
}

protocol IGethProviderProtocol {
    func getGasPrice() -> Single<Wei>
    func getBalance(address: String, blockParameter: BlockParameter) -> Single<Balance>
    func getBlockNumber() -> Single<Int>
    func getTransactionCount(address: String, blockParameter: BlockParameter) -> Single<Int>
    func sendRawTransaction(rawTransaction: String) -> Single<SentTransaction>
    func getTransactions(address: String, startBlock: Int64) -> Single<Transactions>
}

protocol IPeriodicTimer {
    var delegate: IPeriodicTimerDelegate? { get set }
    func schedule()
}

protocol IPeriodicTimerDelegate: class {
    func onFire()
}

protocol IRefreshKitDelegate: class {
    func onRefresh()
}

protocol IRefreshManager {
    func didRefresh()
}