import Foundation
import EthereumKit
import RxSwift

class EthereumAdapter {
    private let ethereumKit: Kit
    private let decimal = 18

    init(ethereumKit: Kit) {
        self.ethereumKit = ethereumKit
    }

    private func transactionRecord(fromTransaction transaction: TransactionInfo) -> TransactionRecord {
        let from = TransactionAddress(
                address: transaction.from,
                mine: transaction.from == receiveAddress
        )

        let to = TransactionAddress(
                address: transaction.to,
                mine: transaction.to == receiveAddress
        )

        var amount: Decimal = 0

        if let significand = Decimal(string: transaction.value) {
            let sign: FloatingPointSign = from.mine ? .minus : .plus
            amount = Decimal(sign: sign, exponent: -decimal, significand: significand)
        }
        let isError = (transaction.isError ?? 0) != 0

        return TransactionRecord(
                transactionHash: transaction.hash,
                transactionIndex: transaction.transactionIndex ?? 0,
                interTransactionIndex: 0,
                amount: amount,
                timestamp: transaction.timestamp,
                from: from,
                to: to,
                blockHeight: transaction.blockNumber,
                isError: isError
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
        if let balanceString = ethereumKit.balance, let significand = Decimal(string: balanceString) {
            return Decimal(sign: .plus, exponent: -decimal, significand: significand)
        }

        return 0
    }

    var receiveAddress: String {
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

    func validate(address: String) throws {
        try EthereumKit.Kit.validate(address: address)
    }

    func sendSingle(to: String, amount: Decimal, gasLimit: Int) -> Single<Void> {
        ethereumKit.sendSingle(to: to, value: amount.roundedString(decimal: decimal), gasPrice: 5_000_000_000, gasLimit: gasLimit).map { _ in ()}
    }

    func transactionsSingle(from: (hash: String, interTransactionIndex: Int)?, limit: Int?) -> Single<[TransactionRecord]> {
        ethereumKit.transactionsSingle(fromHash: from?.hash, limit: limit)
                .map { [weak self] in
                    $0.compactMap {
                        self?.transactionRecord(fromTransaction: $0)
                    }
                }
    }

    func transaction(hash: String, interTransactionIndex: Int) -> TransactionRecord? {
        ethereumKit.transaction(hash: hash).map { transactionRecord(fromTransaction: $0) }
    }

    func estimatedGasLimit(to address: String, value: Decimal) -> Single<Int> {
        Single.just(ethereumKit.gasLimit)
    }

}
