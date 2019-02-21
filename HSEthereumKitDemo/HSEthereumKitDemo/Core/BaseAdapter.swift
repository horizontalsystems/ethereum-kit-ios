import Foundation
import RxSwift
import HSEthereumKit

class BaseAdapter {
    let ethereumKit: EthereumKit
    let decimal: Int

    let balanceSignal = Signal()
    let lastBlockHeightSignal = Signal()
    let syncStateSignal = Signal()
    let transactionsSignal = Signal()

    init(ethereumKit: EthereumKit, decimal: Int) {
        self.ethereumKit = ethereumKit
        self.decimal = decimal
    }

    var syncState: EthereumKit.SyncState {
        return .notSynced
    }

    func transactionRecord(fromTransaction transaction: EthereumTransaction) -> TransactionRecord {
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

        if let significand = Decimal(string: transaction.amount) {
            let sign: FloatingPointSign = from.mine ? .minus : .plus
            amount = Decimal(sign: sign, exponent: -decimal, significand: significand)
        }

        return TransactionRecord(
                transactionHash: transaction.hash,
                blockHeight: transaction.blockNumber,
                amount: amount,
                timestamp: Double(transaction.timestamp),
                from: from,
                to: to
        )
    }

    func transactionsObservable(hashFrom: String? = nil, limit: Int? = nil) -> Single<[EthereumTransaction]> {
        return Single.just([])
    }

    var balanceString: String? {
        return nil
    }

    func sendSingle(to address: String, amount: String) -> Single<Void> {
        return Single.just(())
    }

}

extension BaseAdapter {

    var balance: Decimal {
        if let balanceString = balanceString, let significand = Decimal(string: balanceString) {
            return Decimal(sign: .plus, exponent: -decimal, significand: significand)
        }

        return 0
    }

    var lastBlockHeight: Int? {
        return ethereumKit.lastBlockHeight
    }

    func validate(address: String) throws {
        try ethereumKit.validate(address: address)
    }

    var receiveAddress: String {
        return ethereumKit.receiveAddress
    }

    func transactionsSingle(hashFrom: String? = nil, limit: Int? = nil) -> Single<[TransactionRecord]> {
        return transactionsObservable(hashFrom: hashFrom, limit: limit)
                .map { [unowned self] in $0.map { self.transactionRecord(fromTransaction: $0) }}
    }

    func sendSingle(to address: String, amount: Decimal) -> Single<Void> {
        let poweredDecimal = amount * pow(10, decimal)
        let handler = NSDecimalNumberHandler(roundingMode: .plain, scale: 0, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
        let roundedDecimal = NSDecimalNumber(decimal: poweredDecimal).rounding(accordingToBehavior: handler).decimalValue

        let amountString = String(describing: roundedDecimal)

        return sendSingle(to: address, amount: amountString)
    }

}

extension BaseAdapter {

    func onUpdate(transactions: [EthereumTransaction]) {
        transactionsSignal.notify()
    }

    func onUpdateBalance() {
        balanceSignal.notify()
    }

    func onUpdateLastBlockHeight() {
        lastBlockHeightSignal.notify()
    }

    func onUpdateSyncState() {
        syncStateSignal.notify()
    }

}
