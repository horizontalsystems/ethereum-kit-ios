import RxSwift
import BigInt
import EthereumKit

class TransactionManager {
    private let scheduler = ConcurrentDispatchQueueScheduler(queue: DispatchQueue(label: "transactionManager.handle_logs", qos: .background))
    private let disposeBag = DisposeBag()

    weak var delegate: ITransactionManagerDelegate?

    private let contractAddress: Data
    private let address: Data
    private let storage: ITransactionStorage
    private let dataProvider: IDataProvider
    private let transactionBuilder: ITransactionBuilder

    init(contractAddress: Data, address: Data, storage: ITransactionStorage, dataProvider: IDataProvider, transactionBuilder: ITransactionBuilder) {
        self.contractAddress = contractAddress
        self.address = address
        self.storage = storage
        self.dataProvider = dataProvider
        self.transactionBuilder = transactionBuilder
    }

    private func handle(logs: [EthereumLog]) {
        // remove all logs with zero value which has another log with same txHash
        let nonZeroLogs = logs.filter { log in
            logs.filter { $0.transactionHash == log.transactionHash }.count == 1 || log.data.contains { element in element != 0 }
        }
        var pendingTransactions = storage.pendingTransactions

        let updatedTransactions = nonZeroLogs.map { log -> Transaction in
            var index = log.logIndex
            let value = BigUInt(log.data.toRawHexString(), radix: 16)!
            let from = log.topics[1].suffix(from: 12)
            let to = log.topics[2].suffix(from: 12)

            if let txIndex = pendingTransactions.firstIndex(where: { $0.transactionHash == log.transactionHash && $0.from == from && $0.to == to }) {
                pendingTransactions.remove(at: txIndex)
                index = 0
            }

            let transaction = Transaction(transactionHash: log.transactionHash, transactionIndex: log.transactionIndex, from: from, to: to, value: value, timestamp: log.timestamp ?? Date().timeIntervalSince1970, interTransactionIndex: index)

            transaction.logIndex = log.logIndex
            transaction.blockHash = log.blockHash
            transaction.blockNumber = log.blockNumber

            return transaction
        }

        guard !pendingTransactions.isEmpty else {
            finishSync(transactions: updatedTransactions)
            return
        }

        dataProvider.getTransactionStatuses(transactionHashes: pendingTransactions.map { $0.transactionHash })
                .observeOn(scheduler)
                .map { [weak self] statuses -> [Transaction] in
                    self?.updateFailStatus(pendingTransactions: pendingTransactions, statuses: statuses) ?? []
                }
                .subscribe(onSuccess: { [weak self] failedTransactions in
                    self?.finishSync(transactions: updatedTransactions + failedTransactions)
                }, onError: { [weak self] _ in
                    self?.finishSync(transactions: updatedTransactions)
                })
                .disposed(by: disposeBag)
    }

    private func finishSync(transactions: [Transaction]) {
        storage.save(transactions: transactions)
        delegate?.onSyncSuccess(transactions: transactions)
    }

    private func updateFailStatus(pendingTransactions: [Transaction], statuses: [(Data, TransactionStatus)]) -> [Transaction] {
        statuses.compactMap { (hash, status) -> Transaction? in
            if status == .failed || status == .notFound,
               let txIndex = pendingTransactions.firstIndex(where: { $0.transactionHash == hash }) {
                pendingTransactions[txIndex].isError = true
                return pendingTransactions[txIndex]
            }
            return nil
        }
    }

}

extension TransactionManager: ITransactionManager {

    var lastTransactionBlockHeight: Int? {
        storage.lastTransactionBlockHeight
    }

    func transactionsSingle(from: (hash: Data, interTransactionIndex: Int)?, limit: Int?) -> Single<[Transaction]> {
        storage.transactionsSingle(from: from, limit: limit)
    }

    func transactionContractData(to: Data, value: BigUInt) -> Data {
        transactionBuilder.transferTransactionInput(to: to, value: value)
    }

    func sendSingle(to: Data, value: BigUInt, gasPrice: Int, gasLimit: Int) -> Single<Transaction> {
        let transactionInput = transactionBuilder.transferTransactionInput(to: to, value: value)

        return dataProvider.sendSingle(contractAddress: contractAddress, transactionInput: transactionInput, gasPrice: gasPrice, gasLimit: gasLimit)
                .map { [unowned self] hash in
                    Transaction(transactionHash: hash, from: self.address, to: to, value: value)
                }
                .do(onSuccess: { [weak self] transaction in
                    self?.storage.save(transactions: [transaction])
                })
    }

    func sync() {
        let lastBlockHeight = dataProvider.lastBlockHeight
        let lastTransactionBlockHeight = storage.lastTransactionBlockHeight ?? 0

        dataProvider.getTransactionLogs(contractAddress: contractAddress, address: address, from: lastTransactionBlockHeight + 1, to: lastBlockHeight)
                .subscribeOn(scheduler)
                .subscribe(onSuccess: { [weak self] logs in
                    self?.handle(logs: logs)
                }, onError: { [weak self] error in
                    self?.delegate?.onSyncTransactionsError()
                })
                .disposed(by: disposeBag)
    }

}
