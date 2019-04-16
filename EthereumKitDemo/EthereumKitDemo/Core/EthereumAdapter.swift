import EthereumKit
import RxSwift

class EthereumAdapter: BaseAdapter {

    init(ethereumKit: EthereumKit) {
        super.init(ethereumKit: ethereumKit, decimal: 18)

        ethereumKit.add(delegate: self)
    }

    private func transactionRecord(fromTransaction transaction: TransactionInfo) -> TransactionRecord {
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
                transactionHash: transaction.hash,
                blockHeight: transaction.blockNumber,
                amount: amount,
                timestamp: transaction.timestamp,
                from: from,
                to: to
        )
    }

    override var syncState: EthereumKit.SyncState {
        return ethereumKit.syncState
    }

    override var balanceString: String? {
        return ethereumKit.balance
    }

    override func sendSingle(to: String, value: String) -> Single<Void> {
        return ethereumKit.sendSingle(to: to, value: value, gasPrice: 5_000_000_000).map { _ in ()}
    }

    override func transactionsSingle(hashFrom: String? = nil, limit: Int? = nil) -> Single<[TransactionRecord]> {
        return ethereumKit.transactionsSingle(fromHash: hashFrom, limit: limit)
                .map { [unowned self] in $0.map { self.transactionRecord(fromTransaction: $0) }}
    }

}

extension EthereumAdapter: IEthereumKitDelegate {

    public func onUpdate(transactions: [TransactionInfo]) {
        transactionsSignal.notify()
    }

    public func onUpdateBalance() {
        balanceSignal.notify()
    }

    public func onUpdateLastBlockHeight() {
        lastBlockHeightSignal.notify()
    }

    public func onUpdateSyncState() {
        syncStateSignal.notify()
    }

}
