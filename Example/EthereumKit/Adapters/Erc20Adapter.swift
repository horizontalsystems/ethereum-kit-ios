import EthereumKit
import class EthereumKit.Logger
import Erc20Kit
import class Erc20Kit.TransactionInfo
import RxSwift

class Erc20Adapter {
    private let ethereumKit: EthereumKit.Kit
    private let erc20Kit: Erc20Kit.Kit

    let name: String
    let coin: String

    private let contractAddress: String
    private let decimal: Int

    init(ethereumKit: EthereumKit.Kit, name: String, coin: String, contractAddress: String, decimal: Int) {
        self.ethereumKit = ethereumKit
        self.erc20Kit = try! Kit.instance(
                ethereumKit: ethereumKit,
                contractAddress: contractAddress
        )

        self.name = name
        self.coin = coin

        self.contractAddress = contractAddress
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
                blockHeight: transaction.blockNumber,
                isError: transaction.isError
        )
    }

}

extension Erc20Adapter: IAdapter {

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

    var balance: Decimal {
        if let balanceString = erc20Kit.balance, let significand = Decimal(string: balanceString) {
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
        erc20Kit.syncStateObservable.map { _ in () }
    }

    var balanceObservable: Observable<Void> {
        erc20Kit.balanceObservable.map { _ in () }
    }

    var transactionsObservable: Observable<Void> {
        erc20Kit.transactionsObservable.map { _ in () }
    }

    func validate(address: String) throws {
        try ethereumKit.validate(address: address)
    }

    func sendSingle(to: String, amount: Decimal, gasLimit: Int) -> Single<Void> {
        try! erc20Kit.sendSingle(to: to, value: amount.roundedString(decimal: decimal), gasPrice: 5_000_000_000, gasLimit: gasLimit).map { _ in ()}
    }

    func transactionsSingle(from: (hash: String, interTransactionIndex: Int)?, limit: Int?) -> Single<[TransactionRecord]> {
        try! erc20Kit.transactionsSingle(from: from, limit: limit)
                .map { [weak self] in
                    $0.compactMap {
                        self?.transactionRecord(fromTransaction: $0)
                    }
                }
    }

    func estimatedGasLimit(to address: String, value: Decimal) -> Single<Int> {
        erc20Kit.estimateGas(to: address, contractAddress: contractAddress, value: value.roundedString(decimal: decimal), gasPrice: 5_000_000_000)
    }

}
