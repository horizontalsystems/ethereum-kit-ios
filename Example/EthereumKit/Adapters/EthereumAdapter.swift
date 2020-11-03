import Foundation
import EthereumKit
import RxSwift
import BigInt

class EthereumAdapter {
    let ethereumKit: Kit
    private let decimal = 18

    init(ethereumKit: Kit) {
        self.ethereumKit = ethereumKit
    }

    private func transactionRecord(transactionWithInternal: TransactionWithInternal) -> TransactionRecord {
        let transaction = transactionWithInternal.transaction

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

        for internalTransaction in transactionWithInternal.internalTransactions {
            if let significand = Decimal(string: internalTransaction.value.description), significand != 0 {
                let mine = internalTransaction.from == receiveAddress
                let sign: FloatingPointSign = mine ? .minus : .plus
                let internalTransactionAmount = Decimal(sign: sign, exponent: -decimal, significand: significand)
                amount += internalTransactionAmount
            }
        }

        let isError = (transaction.isError ?? 0) != 0

        return TransactionRecord(
                transactionHash: transaction.hash.toHexString(),
                transactionHashData: transaction.hash,
                transactionIndex: transaction.transactionIndex ?? 0,
                interTransactionIndex: 0,
                amount: amount,
                timestamp: transaction.timestamp,
                from: from,
                to: to,
                blockHeight: transaction.blockNumber,
                isError: isError,
                type: ""
        )
    }

}

extension EthereumAdapter: IAdapter {

    func refresh() {
        ethereumKit.refresh()
    }

    var name: String {
        "Ethereum"
    }

    var coin: String {
        "ETH"
    }

    var lastBlockHeight: Int? {
        ethereumKit.lastBlockHeight
    }

    var syncState: SyncState {
        ethereumKit.syncState
    }

    var transactionsSyncState: SyncState {
        ethereumKit.transactionsSyncState
    }

    var balance: Decimal {
        if let balance = ethereumKit.balance, let significand = Decimal(string: balance.description) {
            return Decimal(sign: .plus, exponent: -decimal, significand: significand)
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
        ethereumKit.syncStateObservable.map { _ in () }
    }

    var transactionsSyncStateObservable: Observable<Void> {
        ethereumKit.transactionsSyncStateObservable.map { _ in () }
    }

    var balanceObservable: Observable<Void> {
        ethereumKit.balanceObservable.map { _ in () }
    }

    var transactionsObservable: Observable<Void> {
        ethereumKit.transactionsObservable.map { _ in () }
    }

    func sendSingle(to: Address, amount: Decimal, gasLimit: Int) -> Single<Void> {
        let amount = BigUInt(amount.roundedString(decimal: decimal))!

        return ethereumKit.sendSingle(address: to, value: amount, gasPrice: 5_000_000_000, gasLimit: gasLimit).map { _ in ()}
    }

    func transactionsSingle(from: (hash: Data, interTransactionIndex: Int)?, limit: Int?) -> Single<[TransactionRecord]> {
        ethereumKit.transactionsSingle(fromHash: from?.hash, limit: limit)
                .map { [weak self] in
                    $0.compactMap {
                        self?.transactionRecord(transactionWithInternal: $0)
                    }
                }
    }

    func transaction(hash: Data, interTransactionIndex: Int) -> TransactionRecord? {
        ethereumKit.transaction(hash: hash).map { transactionRecord(transactionWithInternal: $0) }
    }

    func estimatedGasLimit(to address: Address, value: Decimal) -> Single<Int> {
        let value = BigUInt(value.roundedString(decimal: decimal))!

        return ethereumKit.estimateGas(to: address, amount: value, gasPrice: 5_000_000_000)
    }

}
