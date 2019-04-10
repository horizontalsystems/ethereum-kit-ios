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

    var balanceString: String? {
        return nil
    }

    func sendSingle(to: String, value: String) -> Single<Void> {
        return Single.just(())
    }

    func transactionsSingle(hashFrom: String? = nil, limit: Int? = nil) -> Single<[TransactionRecord]> {
        return Single.just([])
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

    func sendSingle(to address: String, amount: Decimal) -> Single<Void> {
        let poweredDecimal = amount * pow(10, decimal)
        let handler = NSDecimalNumberHandler(roundingMode: .plain, scale: 0, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
        let roundedDecimal = NSDecimalNumber(decimal: poweredDecimal).rounding(accordingToBehavior: handler).decimalValue

        let amountString = String(describing: roundedDecimal)

        return sendSingle(to: address, value: amountString)
    }

}

extension BaseAdapter {

    enum SendError: Error {
        case invalidAddress
        case invalidAmount
    }

}
