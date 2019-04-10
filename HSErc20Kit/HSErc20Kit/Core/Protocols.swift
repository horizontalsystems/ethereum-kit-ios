import RxSwift
import HSEthereumKit

public protocol IErc20TokenDelegate: class {
    func onUpdate(transactions: [TransactionInfo])
    func onUpdateBalance()
    func onUpdateSyncState()
}

protocol ITransactionsProvider {
    func transactionsErc20Single(address: Data, startBlock: Int) -> Single<[Transaction]>
}

protocol IBalanceSyncerDelegate: class {
    var tokens: [Data: Token] { get }
    func send(request: IRequest)
    func onSyncStateUpdated(contractAddress: Data, state: EthereumKit.SyncState)
    func onBalanceUpdated(contractAddress: Data)
}

protocol ITransactionSyncerDelegate: class {
    func send(request: IRequest)
    func onSyncStateUpdated(state: EthereumKit.SyncState)
}
