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

    private let contractAddress: String
    private let decimal: Int

    init(ethereumKit: EthereumKit, erc20Kit: Erc20Kit, name: String, coin: String, contractAddress: String, balancePosition: Int, decimal: Int, minLogLevel: Logger.Level = .verbose) {
        self.ethereumKit = ethereumKit
        self.erc20Kit = erc20Kit

        self.name = name
        self.coin = coin

        self.contractAddress = contractAddress
        self.decimal = decimal

        try! erc20Kit.register(contractAddress: contractAddress, balancePosition: balancePosition)
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
                index: transaction.logIndex ?? 0,
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
        switch try! erc20Kit.syncState(contractAddress: contractAddress) {
        case .notSynced: return EthereumKit.SyncState.notSynced
        case .syncing: return EthereumKit.SyncState.syncing
        case .synced: return EthereumKit.SyncState.synced
        }
    }

    var balance: Decimal {
        if let balanceString = try! erc20Kit.balance(contractAddress: contractAddress), let significand = Decimal(string: balanceString) {
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
        return try! erc20Kit.syncStateObservable(contractAddress: contractAddress).map { _ in () }
    }

    var balanceObservable: Observable<Void> {
        return try! erc20Kit.balanceObservable(contractAddress: contractAddress).map { _ in () }
    }

    var transactionsObservable: Observable<Void> {
        return try! erc20Kit.transactionsObservable(contractAddress: contractAddress).map { _ in () }
    }

    func validate(address: String) throws {
        try ethereumKit.validate(address: address)
    }

    func sendSingle(to: String, amount: Decimal) -> Single<Void> {
        let poweredDecimal = amount * pow(10, decimal)
        let handler = NSDecimalNumberHandler(roundingMode: .plain, scale: 0, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
        let roundedDecimal = NSDecimalNumber(decimal: poweredDecimal).rounding(accordingToBehavior: handler).decimalValue

        let value = String(describing: roundedDecimal)

        return try! erc20Kit.sendSingle(contractAddress: contractAddress, to: to, value: value, gasPrice: 5_000_000_000).map { _ in ()}
    }

    func transactionsSingle(from: (hash: String, index: Int)?, limit: Int?) -> Single<[TransactionRecord]> {
        return try! erc20Kit.transactionsSingle(contractAddress: contractAddress, from: from, limit: limit)
                .map { [weak self] in
                    $0.compactMap {
                        self?.transactionRecord(fromTransaction: $0)
                    }
                }
    }

}
