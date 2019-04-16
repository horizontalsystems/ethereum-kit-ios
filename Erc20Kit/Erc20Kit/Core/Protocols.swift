import RxSwift
import EthereumKit

public protocol IErc20TokenDelegate: class {
    func onUpdate(transactions: [TransactionInfo])
    func onUpdateBalance()
    func onUpdateSyncState()
}

protocol IBalanceSyncerDelegate: class {
    func onBalanceUpdated(contractAddress: Data)
}

protocol ITransactionSyncerDelegate: class {
    func onTransactionsUpdated(contractAddress: Data, transactions: [Transaction], blockNumber: Int)
}

protocol ITokenStatesDelegate: class {
    func onSyncStateUpdated(contractAddress: Data)
}

protocol ITransactionsProvider {
    func transactionsErc20Single(address: Data, startBlock: Int) -> Single<[Transaction]>
}

protocol ITransactionBuilder {
    func transferTransactionInput(to toAddress: Data, value: BInt) -> Data
}

protocol ITransactionSyncer {
    func sync(forBlock blockNumber: Int)
}

protocol IBalanceSyncer {
    func sync(forBlock blockNumber: Int, token: Token)
    func setSynced(forBlock: Int, token: Token)
}

protocol IDataProvider {
    func getLogs(from: Int, to: Int, completionFunction: @escaping ([Transaction], Int) -> ())
    func getStorageAt(for token: Token, toBlock: Int, completeFunction: @escaping (Token, BInt, Int) -> ())
}

protocol ITokensHolder {
    var tokens: [Data: Token] { get }

    func add(token: Token)
    func token(byContractAddress contractAddress: Data) -> Token?
    func clear()
}

protocol ITokenStates {
    var states: [Data: Erc20Kit.SyncState] { get }

    func state(of contractAddress: Data) -> Erc20Kit.SyncState
    func set(state: Erc20Kit.SyncState, to contractAddress: Data)
    func clear()
}