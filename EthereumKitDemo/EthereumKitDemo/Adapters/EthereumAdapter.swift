import Foundation
import EthereumKit
import RxSwift

class EthereumAdapter {
    private let ethereumKit: EthereumKit
    private let decimal = 18

    init(ethereumKit: EthereumKit) {
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

        return TransactionRecord(
                transactionHash: transaction.hash,
                transactionIndex: transaction.transactionIndex ?? 0,
                interTransactionIndex: 0,
                amount: amount,
                timestamp: transaction.timestamp,
                from: from,
                to: to,
                blockHeight: transaction.blockNumber
        )
    }

}

extension EthereumAdapter: IAdapter {

    var name: String {
        return "Ethereum"
    }

    var coin: String {
        return "ETH"
    }

    var lastBlockHeight: Int? {
        return ethereumKit.lastBlockHeight
    }

    var syncState: EthereumKit.SyncState {
        return ethereumKit.syncState
    }

    var balance: Decimal {
        if let balanceString = ethereumKit.balance, let significand = Decimal(string: balanceString) {
            return Decimal(sign: .plus, exponent: -decimal, significand: significand)
        }

        return 0
    }

    var receiveAddress: String {
        return ethereumKit.receiveAddress
    }

    var lastBlockHeightObservable: Observable<Void> {
        return ethereumKit.lastBlockHeightObservable.map { _ in () }
    }

    var syncStateObservable: Observable<Void> {
        return ethereumKit.syncStateObservable.map { _ in () }
    }

    var balanceObservable: Observable<Void> {
        return ethereumKit.balanceObservable.map { _ in () }
    }

    var transactionsObservable: Observable<Void> {
        return ethereumKit.transactionsObservable.map { _ in () }
    }

    func validate(address: String) throws {
        try ethereumKit.validate(address: address)
    }

    func sendSingle(to: String, amount: Decimal) -> Single<Void> {
        let poweredDecimal = amount * pow(10, decimal)
        let handler = NSDecimalNumberHandler(roundingMode: .plain, scale: 0, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
        let roundedDecimal = NSDecimalNumber(decimal: poweredDecimal).rounding(accordingToBehavior: handler).decimalValue

        let value = String(describing: roundedDecimal)

        return ethereumKit.sendSingle(to: to, value: value, gasPrice: 5_000_000_000).map { _ in ()}
    }

    func transactionsSingle(from: (hash: String, interTransactionIndex: Int)?, limit: Int?) -> Single<[TransactionRecord]> {
        return ethereumKit.transactionsSingle(fromHash: from?.hash, limit: limit)
                .map { [weak self] in
                    $0.compactMap {
                        self?.transactionRecord(fromTransaction: $0)
                    }
                }
    }

}
