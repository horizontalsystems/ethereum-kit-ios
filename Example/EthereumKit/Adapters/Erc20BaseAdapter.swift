import EthereumKit
import Erc20Kit
import RxSwift
import BigInt

class Erc20BaseAdapter: IAdapter {
    let gasPrice = 20_000_000_000
    let ethereumKit: EthereumKit.Kit
    let erc20Kit: Erc20Kit.Kit

    let token: Erc20Token

    init(ethereumKit: EthereumKit.Kit, token: Erc20Token) {
        self.ethereumKit = ethereumKit
        erc20Kit = try! Erc20Kit.Kit.instance(
                ethereumKit: ethereumKit,
                contractAddress: token.contractAddress
        )
        self.token = token
    }

    private func transactionRecord(fromTransaction fullTransaction: FullTransaction) -> TransactionRecord? {
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
            amount = Decimal(sign: sign, exponent: -token.decimal, significand: significand)
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

    func sendSingle(to: Address, amount: Decimal, gasLimit: Int) -> Single<Void> {
        fatalError("Subclasses must override.")
    }

    func start() {
        erc20Kit.start()
    }

    func stop() {
        erc20Kit.stop()
    }

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

    func transactionsSingle(from hash: Data?, limit: Int?) -> Single<[TransactionRecord]> {
        try! erc20Kit.transactionsSingle(from: hash, limit: limit)
                .map { [weak self] in
                    $0.compactMap {
                        self?.transactionRecord(fromTransaction: $0)
                    }
                }
    }

    func transaction(hash: Data, interTransactionIndex: Int) -> TransactionRecord? {
        nil
    }

    func estimatedGasLimit(to address: Address, value: Decimal) -> Single<Int> {
        let value = BigUInt(value.roundedString(decimal: token.decimal))!
        let transactionData = erc20Kit.transferTransactionData(to: address, value: value)

        return ethereumKit.estimateGas(transactionData: transactionData, gasPrice: gasPrice)
    }

}
