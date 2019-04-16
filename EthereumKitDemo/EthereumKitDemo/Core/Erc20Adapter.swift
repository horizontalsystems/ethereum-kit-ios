import EthereumKit
import class EthereumKit.Logger
import Erc20Kit
import class Erc20Kit.TransactionInfo
import RxSwift

class Erc20Adapter: BaseAdapter {
    let erc20Kit: Erc20Kit
    let contractAddress: Data
    let position: Int64

    init(erc20Kit: Erc20Kit, ethereumKit: EthereumKit, contractAddress: Data, position: Int64, decimal: Int, minLogLevel: Logger.Level = .verbose) {
        self.erc20Kit = erc20Kit
        self.contractAddress = contractAddress
        self.position = position

        super.init(ethereumKit: ethereumKit, decimal: decimal)

        self.erc20Kit.register(contractAddress: contractAddress, position: position, decimal: decimal, delegate: self)
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

        var logIndex = ""
        if let index = transaction.logIndex {
            logIndex = String(index, radix: 10)
        }

        return TransactionRecord(
                transactionHash: transaction.transactionHash + logIndex,
                blockHeight: transaction.blockNumber,
                amount: amount,
                timestamp: transaction.timestamp,
                from: from,
                to: to
        )
    }

    override var syncState: EthereumKit.SyncState {
        switch erc20Kit.syncState(contractAddress: contractAddress) {
        case .notSynced: return EthereumKit.SyncState.notSynced
        case .syncing: return EthereumKit.SyncState.syncing
        case .synced: return EthereumKit.SyncState.synced
        }
    }

    override var balanceString: String? {
        return erc20Kit.balance(contractAddress: contractAddress)
    }

    override func sendSingle(to: String, value: String) -> Single<Void> {
        return erc20Kit.sendSingle(contractAddress: contractAddress, to: to, value: value, gasPrice: 5_000_000_000).map { _ in ()}
    }

    override func transactionsSingle(hashFrom: String? = nil, limit: Int? = nil) -> Single<[TransactionRecord]> {
        var resolvedHashFrom: Data? = nil
        var resolvedIndexFrom: Int? = nil

        if let hashFrom = hashFrom {
            resolvedHashFrom = Data(hex: String(hashFrom.prefix(32)))!
            resolvedIndexFrom = Int(String(hashFrom.suffix(33)), radix: 10)
        }

        return erc20Kit.transactionsSingle(contractAddress: contractAddress, hashFrom: resolvedHashFrom, indexFrom: resolvedIndexFrom, limit: limit)
                .map { [unowned self] in $0.compactMap { self.transactionRecord(fromTransaction: $0) }}
    }

}

extension Erc20Adapter: IErc20TokenDelegate {

    public func onUpdate(transactions: [TransactionInfo]) {
        transactionsSignal.notify()
    }

    public func onUpdateBalance() {
        balanceSignal.notify()
    }

    public func onUpdateSyncState() {
        syncStateSignal.notify()
    }

}
