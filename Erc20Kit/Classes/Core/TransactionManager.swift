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
    private let transactionProvider: ITransactionProvider
    private let dataProvider: IDataProvider
    private let transactionBuilder: ITransactionBuilder

    init(contractAddress: Data, address: Data, storage: ITransactionStorage, transactionProvider: ITransactionProvider, dataProvider: IDataProvider, transactionBuilder: ITransactionBuilder) {
        self.contractAddress = contractAddress
        self.address = address
        self.storage = storage
        self.transactionProvider = transactionProvider
        self.dataProvider = dataProvider
        self.transactionBuilder = transactionBuilder
    }

    private func handle(transactions: [Transaction]) {
        var pendingTransactions = storage.pendingTransactions

        for transaction in transactions {
            if let txIndex = pendingTransactions.firstIndex(where: { $0.transactionHash == transaction.transactionHash && $0.from == transaction.from && $0.to == transaction.to }) {
                pendingTransactions.remove(at: txIndex)

                // when this transaction was sent interTransactionIndex was set to 0, so we need it to set 0 for it to replace the transaction in database
                transaction.interTransactionIndex = 0
            }
        }

        guard !pendingTransactions.isEmpty else {
            finishSync(transactions: transactions)
            return
        }

        dataProvider.getTransactionStatuses(transactionHashes: pendingTransactions.map { $0.transactionHash })
                .observeOn(scheduler)
                .map { [weak self] statuses -> [Transaction] in
                    self?.failedTransactions(pendingTransactions: pendingTransactions, statuses: statuses) ?? []
                }
                .subscribe(onSuccess: { [weak self] failedTransactions in
                    self?.finishSync(transactions: transactions + failedTransactions)
                }, onError: { [weak self] _ in
                    self?.finishSync(transactions: transactions)
                })
                .disposed(by: disposeBag)
    }

    private func finishSync(transactions: [Transaction]) {
        storage.save(transactions: transactions)
        delegate?.onSyncSuccess(transactions: transactions)
    }

    private func failedTransactions(pendingTransactions: [Transaction], statuses: [(Data, TransactionStatus)]) -> [Transaction] {
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

        transactionProvider.transactions(contractAddress: contractAddress, address: address, from: lastTransactionBlockHeight + 1, to: lastBlockHeight)
                .subscribeOn(scheduler)
                .subscribe(onSuccess: { [weak self] transactions in
                    self?.handle(transactions: transactions.filter { $0.value != 0 })
                }, onError: { [weak self] error in
                    self?.delegate?.onSyncTransactionsFailed(error: error)
                })
                .disposed(by: disposeBag)
    }

}
