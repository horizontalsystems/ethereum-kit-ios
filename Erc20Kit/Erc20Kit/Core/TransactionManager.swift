import RxSwift
import BigInt
import EthereumKit

class TransactionManager {
    weak var delegate: ITransactionManagerDelegate?

    private let disposeBag = DisposeBag()

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
        let pendingTransactions = storage.pendingTransactions

        let transactions = logs.map { log -> Transaction in
            var index = log.logIndex
            let value = BigUInt(log.data.toRawHexString(), radix: 16)!
            let from = log.topics[1].suffix(from: 12)
            let to = log.topics[2].suffix(from: 12)

            if pendingTransactions.contains(where: { $0.transactionHash == log.transactionHash && $0.from == from && $0.to == to }) {
                index = 0
            }

            let transaction = Transaction(transactionHash: log.transactionHash, transactionIndex: log.transactionIndex, from: from, to: to, value: value, timestamp: log.timestamp ?? Date().timeIntervalSince1970, interTransactionIndex: index)

            transaction.logIndex = log.logIndex
            transaction.blockHash = log.blockHash
            transaction.blockNumber = log.blockNumber

            return transaction
        }

        storage.save(transactions: transactions)
        delegate?.onSyncSuccess(transactions: transactions)
    }

}

extension TransactionManager: ITransactionManager {

    var lastTransactionBlockHeight: Int? {
        return storage.lastTransactionBlockHeight
    }

    func transactionsSingle(from: (hash: Data, interTransactionIndex: Int)?, limit: Int?) -> Single<[Transaction]> {
        return storage.transactionsSingle(from: from, limit: limit)
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
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onSuccess: { [weak self] logs in
                    self?.handle(logs: logs)
                }, onError: { [weak self] error in
                    self?.delegate?.onSyncTransactionsError()
                })
                .disposed(by: disposeBag)
    }

}
