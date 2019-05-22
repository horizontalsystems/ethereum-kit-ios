import EthereumKit
import class EthereumKit.Logger
import Erc20Kit
import class Erc20Kit.TransactionInfo
import RxSwift

class Erc20Adapter {
    private let ethereumKit: EthereumKit
    private let erc20Kit: Erc20Kit

    let name: String
    let coin: String

    private let decimal: Int

    init(ethereumKit: EthereumKit, name: String, coin: String, contractAddress: String, decimal: Int) {
        self.ethereumKit = ethereumKit
        self.erc20Kit = try! Erc20Kit.instance(
                ethereumKit: ethereumKit,
                contractAddress: contractAddress
        )

        self.name = name
        self.coin = coin

        self.decimal = decimal
    }

    private func transactionRecord(fromTransaction transaction: TransactionInfo) -> TransactionRecord? {
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

        if let significand = Decimal(string: transaction.value) {
            let sign: FloatingPointSign = from.mine ? .minus : .plus
            amount = Decimal(sign: sign, exponent: -decimal, significand: significand)
        }

        return TransactionRecord(
                transactionHash: transaction.transactionHash,
                transactionIndex: transaction.transactionIndex ?? 0,
                interTransactionIndex: transaction.interTransactionIndex,
                amount: amount,
                timestamp: transaction.timestamp,
                from: from,
                to: to,
                blockHeight: transaction.blockNumber
        )
    }

}

extension Erc20Adapter: IAdapter {

    var lastBlockHeight: Int? {
        return ethereumKit.lastBlockHeight
    }

    var syncState: EthereumKit.SyncState {
        switch erc20Kit.syncState {
        case .notSynced: return EthereumKit.SyncState.notSynced
        case .syncing: return EthereumKit.SyncState.syncing(progress: nil)
        case .synced: return EthereumKit.SyncState.synced
        }
    }

    var balance: Decimal {
        if let balanceString = erc20Kit.balance, let significand = Decimal(string: balanceString) {
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
        return erc20Kit.syncStateObservable.map { _ in () }
    }

    var balanceObservable: Observable<Void> {
        return erc20Kit.balanceObservable.map { _ in () }
    }

    var transactionsObservable: Observable<Void> {
        return erc20Kit.transactionsObservable.map { _ in () }
    }

    func validate(address: String) throws {
        try ethereumKit.validate(address: address)
    }

    func sendSingle(to: String, amount: Decimal) -> Single<Void> {
        let poweredDecimal = amount * pow(10, decimal)
        let handler = NSDecimalNumberHandler(roundingMode: .plain, scale: 0, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
        let roundedDecimal = NSDecimalNumber(decimal: poweredDecimal).rounding(accordingToBehavior: handler).decimalValue

        let value = String(describing: roundedDecimal)

        return try! erc20Kit.sendSingle(to: to, value: value, gasPrice: 5_000_000_000).map { _ in ()}
    }

    func transactionsSingle(from: (hash: String, interTransactionIndex: Int)?, limit: Int?) -> Single<[TransactionRecord]> {
        return try! erc20Kit.transactionsSingle(from: from, limit: limit)
                .map { [weak self] in
                    $0.compactMap {
                        self?.transactionRecord(fromTransaction: $0)
                    }
                }
    }

}
