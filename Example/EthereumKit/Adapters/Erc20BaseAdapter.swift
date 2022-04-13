import Foundation
import EthereumKit
import Erc20Kit
import RxSwift
import BigInt

class Erc20BaseAdapter: IAdapter {
    let ethereumKit: EthereumKit.Kit
    let erc20Kit: Erc20Kit.Kit

    let token: Erc20Token

    init(ethereumKit: EthereumKit.Kit, token: Erc20Token) {
        self.ethereumKit = ethereumKit
        erc20Kit = try! Erc20Kit.Kit.instance(
                ethereumKit: ethereumKit,
                contractAddress: token.contractAddress
        )
        self.token = token
    }

    private func transactionRecord(fromTransaction fullTransaction: FullTransaction) -> TransactionRecord? {
        let transaction = fullTransaction.transaction

        var amount: Decimal?

        if let value = transaction.value, let significand = Decimal(string: value.description) {
            amount = Decimal(sign: .plus, exponent: -token.decimal, significand: significand)
        }

        return TransactionRecord(
                transactionHash: transaction.hash.toHexString(),
                transactionHashData: transaction.hash,
                timestamp: transaction.timestamp,
                isFailed: transaction.isFailed,
                from: transaction.from,
                to: transaction.to,
                amount: amount,
                input: transaction.input.map { $0.toHexString() },
                blockHeight: transaction.blockNumber,
                transactionIndex: transaction.transactionIndex,
                decoration: String(describing: fullTransaction.decoration)
        )
    }

    func sendSingle(to: Address, amount: Decimal, gasLimit: Int, gasPrice: GasPrice) -> Single<Void> {
        fatalError("Subclasses must override.")
    }

    func start() {
        erc20Kit.start()
    }

    func stop() {
        erc20Kit.stop()
    }

    func refresh() {
        erc20Kit.refresh()
    }

    var name: String {
        token.name
    }

    var coin: String {
        token.coin
    }

    var lastBlockHeight: Int? {
        ethereumKit.lastBlockHeight
    }

    var syncState: EthereumKit.SyncState {
        switch erc20Kit.syncState {
        case .synced: return EthereumKit.SyncState.synced
        case .syncing: return EthereumKit.SyncState.syncing(progress: nil)
        case .notSynced(let error): return EthereumKit.SyncState.notSynced(error: error)
        }
    }

    var transactionsSyncState: EthereumKit.SyncState {
        switch erc20Kit.transactionsSyncState {
        case .synced: return EthereumKit.SyncState.synced
        case .syncing: return EthereumKit.SyncState.syncing(progress: nil)
        case .notSynced(let error): return EthereumKit.SyncState.notSynced(error: error)
        }
    }

    var balance: Decimal {
        if let balance = erc20Kit.balance, let significand = Decimal(string: balance.description) {
            return Decimal(sign: .plus, exponent: -token.decimal, significand: significand)
        }

        return 0
    }

    var receiveAddress: Address {
        ethereumKit.receiveAddress
    }

    var lastBlockHeightObservable: Observable<Void> {
        ethereumKit.lastBlockHeightObservable.map { _ in () }
    }

    var syncStateObservable: Observable<Void> {
        erc20Kit.syncStateObservable.map { _ in () }
    }

    var transactionsSyncStateObservable: Observable<Void> {
        erc20Kit.transactionsSyncStateObservable.map { _ in () }
    }

    var balanceObservable: Observable<Void> {
        erc20Kit.balanceObservable.map { _ in () }
    }

    var transactionsObservable: Observable<Void> {
        erc20Kit.transactionsObservable.map { _ in () }
    }

    func transactionsSingle(from hash: Data?, limit: Int?) -> Single<[TransactionRecord]> {
        try! erc20Kit.transactionsSingle(from: hash, limit: limit)
                .map { [weak self] in
                    $0.compactMap {
                        self?.transactionRecord(fromTransaction: $0)
                    }
                }
    }

    func transaction(hash: Data, interTransactionIndex: Int) -> TransactionRecord? {
        nil
    }

    func estimatedGasLimit(to address: Address, value: Decimal, gasPrice: GasPrice) -> Single<Int> {
        let value = BigUInt(value.roundedString(decimal: token.decimal))!
        let transactionData = erc20Kit.transferTransactionData(to: address, value: value)

        return ethereumKit.estimateGas(transactionData: transactionData, gasPrice: gasPrice)
    }

    func transactionSingle(hash: Data) -> Single<FullTransaction> {
        ethereumKit.transactionSingle(hash: hash)
    }

}
