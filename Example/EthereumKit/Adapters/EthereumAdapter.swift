import Foundation
import EthereumKit
import RxSwift
import BigInt

class EthereumAdapter {
    let evmKit: Kit
    private let decimal = 18

    init(ethereumKit: Kit) {
        evmKit = ethereumKit
    }

    private func transactionRecord(fullTransaction: FullTransaction) -> TransactionRecord {
        let transaction = fullTransaction.transaction

        let from = TransactionAddress(
                address: transaction.from,
                mine: transaction.from == receiveAddress
        )

        let to = TransactionAddress(
                address: transaction.to,
                mine: transaction.to == receiveAddress
        )

        var amount: Decimal = 0

        if let significand = Decimal(string: transaction.value.description), significand != 0 {
            let sign: FloatingPointSign = from.mine ? .minus : .plus
            amount = Decimal(sign: sign, exponent: -decimal, significand: significand)
        }

        for internalTransaction in fullTransaction.internalTransactions {
            if let significand = Decimal(string: internalTransaction.value.description), significand != 0 {
                let mine = internalTransaction.from == receiveAddress
                let sign: FloatingPointSign = mine ? .minus : .plus
                let internalTransactionAmount = Decimal(sign: sign, exponent: -decimal, significand: significand)
                amount += internalTransactionAmount
            }
        }

        return TransactionRecord(
                transactionHash: transaction.hash.toHexString(),
                transactionHashData: transaction.hash,
                transactionIndex: fullTransaction.receiptWithLogs?.receipt.transactionIndex ?? 0,
                interTransactionIndex: 0,
                amount: amount,
                timestamp: transaction.timestamp,
                from: from,
                to: to,
                blockHeight: fullTransaction.receiptWithLogs?.receipt.blockNumber,
                isError: fullTransaction.failed,
                type: "",
                mainDecoration: fullTransaction.mainDecoration,
                eventsDecorations: fullTransaction.eventDecorations
        )
    }

}

extension EthereumAdapter: IAdapter {

    func start() {
        evmKit.start()
    }

    func stop() {
        evmKit.stop()
    }

    func refresh() {
        evmKit.refresh()
    }

    var name: String {
        "Ethereum"
    }

    var coin: String {
        "ETH"
    }

    var lastBlockHeight: Int? {
        evmKit.lastBlockHeight
    }

    var syncState: SyncState {
        evmKit.syncState
    }

    var transactionsSyncState: SyncState {
        evmKit.transactionsSyncState
    }

    var balance: Decimal {
        if let balance = evmKit.accountState?.balance, let significand = Decimal(string: balance.description) {
            return Decimal(sign: .plus, exponent: -decimal, significand: significand)
        }

        return 0
    }

    var receiveAddress: Address {
        evmKit.receiveAddress
    }

    var lastBlockHeightObservable: Observable<Void> {
        evmKit.lastBlockHeightObservable.map { _ in () }
    }

    var syncStateObservable: Observable<Void> {
        evmKit.syncStateObservable.map { _ in () }
    }

    var transactionsSyncStateObservable: Observable<Void> {
        evmKit.transactionsSyncStateObservable.map { _ in () }
    }

    var balanceObservable: Observable<Void> {
        evmKit.accountStateObservable.map { _ in () }
    }

    var transactionsObservable: Observable<Void> {
        evmKit.transactionsObservable(tags: [[]]).map { _ in () }
    }

    func sendSingle(to: Address, amount: Decimal, gasLimit: Int) -> Single<Void> {
        let amount = BigUInt(amount.roundedString(decimal: decimal))!
        let transactionData = evmKit.transferTransactionData(to: to, value: amount)

        return evmKit.sendSingle(transactionData: transactionData, gasPrice: 50_000_000_000, gasLimit: gasLimit).map { _ in ()}
    }

    func transactionsSingle(from hash: Data?, limit: Int?) -> Single<[TransactionRecord]> {
        evmKit.transactionsSingle(tags: [], fromHash: hash, limit: limit)
                .map { [weak self] in
                    $0.compactMap {
                        self?.transactionRecord(fullTransaction: $0)
                    }
                }
    }

    func transaction(hash: Data, interTransactionIndex: Int) -> TransactionRecord? {
        evmKit.transaction(hash: hash).map { transactionRecord(fullTransaction: $0) }
    }

    func estimatedGasLimit(to address: Address, value: Decimal) -> Single<Int> {
        let value = BigUInt(value.roundedString(decimal: decimal))!

        return evmKit.estimateGas(to: address, amount: value, gasPrice: 50_000_000_000)
    }

}
