import EthereumKit
import Erc20Kit
import RxSwift
import BigInt

class Erc20Adapter {
    private let ethereumKit: EthereumKit.Kit
    let erc20Kit: Erc20Kit.Kit

    let token: Erc20Token

    init(ethereumKit: EthereumKit.Kit, token: Erc20Token) {
        self.ethereumKit = ethereumKit
        self.erc20Kit = try! Erc20Kit.Kit.instance(
                ethereumKit: ethereumKit,
                contractAddress: token.contractAddress
        )
        self.token = token
    }

    private func transactionRecord(fromTransaction transaction: Erc20Kit.Transaction) -> TransactionRecord? {
        let mineAddress = ethereumKit.receiveAddress

        let from = TransactionAddress(
                address: transaction.from,
                mine: transaction.from == mineAddress
        )

        let to = TransactionAddress(
                address: transaction.to,
                mine: transaction.to == mineAddress
        )

        var amount: Decimal = 0

        if let significand = Decimal(string: transaction.value.description) {
            let sign: FloatingPointSign = from.mine ? .minus : .plus
            amount = Decimal(sign: sign, exponent: -token.decimal, significand: significand)
        }

        return TransactionRecord(
                transactionHash: transaction.transactionHash.toHexString(),
                transactionHashData: transaction.transactionHash,
                transactionIndex: transaction.transactionIndex ?? 0,
                interTransactionIndex: transaction.interTransactionIndex,
                amount: amount,
                timestamp: transaction.timestamp,
                from: from,
                to: to,
                blockHeight: transaction.blockNumber,
                isError: transaction.isError,
                type: transaction.type.rawValue
        )
    }

    func allowanceSingle(spenderAddress: Address) -> Single<Decimal> {
        erc20Kit.allowanceSingle(spenderAddress: spenderAddress)
                .map { [unowned self] allowanceString in
                    if let significand = Decimal(string: allowanceString) {
                        return Decimal(sign: .plus, exponent: -self.token.decimal, significand: significand)
                    }

                    return 0
                }
    }

}

extension Erc20Adapter: IAdapter {

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

    func sendSingle(to: Address, amount: Decimal, gasLimit: Int) -> Single<Void> {
        let amount = BigUInt(amount.roundedString(decimal: token.decimal))!

        return try! erc20Kit.sendSingle(to: to, value: amount, gasPrice: 5_000_000_000, gasLimit: gasLimit).map { _ in ()}
    }

    func transactionsSingle(from: (hash: Data, interTransactionIndex: Int)?, limit: Int?) -> Single<[TransactionRecord]> {
        try! erc20Kit.transactionsSingle(from: from, limit: limit)
                .map { [weak self] in
                    $0.compactMap {
                        self?.transactionRecord(fromTransaction: $0)
                    }
                }
    }

    func transaction(hash: Data, interTransactionIndex: Int) -> TransactionRecord? {
        erc20Kit.transaction(hash: hash, interTransactionIndex: interTransactionIndex).flatMap { transactionRecord(fromTransaction: $0) }
    }

    func estimatedGasLimit(to address: Address, value: Decimal) -> Single<Int> {
        let value = BigUInt(value.roundedString(decimal: token.decimal))!

        return erc20Kit.estimateGas(to: address, contractAddress: token.contractAddress, value: value, gasPrice: 5_000_000_000)
    }

}
