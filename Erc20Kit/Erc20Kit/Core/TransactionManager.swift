import RxSwift
import EthereumKit

class TransactionManager {
    weak var delegate: ITransactionManagerDelegate?

    private let disposeBag = DisposeBag()

    private let address: Data
    private let storage: ITransactionStorage
    private let dataProvider: IDataProvider
    private let transactionBuilder: ITransactionBuilder

    init(address: Data, storage: ITransactionStorage, dataProvider: IDataProvider, transactionBuilder: ITransactionBuilder) {
        self.address = address
        self.storage = storage
        self.dataProvider = dataProvider
        self.transactionBuilder = transactionBuilder
    }

}

extension TransactionManager: ITransactionManager {

    func lastTransactionBlockHeight(contractAddress: Data) -> Int? {
        return storage.lastTransactionBlockHeight(contractAddress: contractAddress)
    }

    func transactionsSingle(contractAddress: Data, from: (hash: Data, index: Int)?, limit: Int?) -> Single<[Transaction]> {
        return storage.transactionsSingle(contractAddress: contractAddress, from: from, limit: limit)
    }

    func sync() {
        let lastBlockHeight = dataProvider.lastBlockHeight
        let lastTransactionBlockHeight = storage.lastTransactionBlockHeight ?? 0

        dataProvider.getTransactions(from: lastTransactionBlockHeight + 1, to: lastBlockHeight, address: address)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onSuccess: { [weak self] transactions in
                    self?.storage.save(transactions: transactions)

                    self?.delegate?.onSyncSuccess(transactions: transactions)
                }, onError: { error in
                    self.delegate?.onSyncTransactionsError()
                })
                .disposed(by: disposeBag)
    }

    func sendSingle(contractAddress: Data, to: Data, value: BInt, gasPrice: Int, gasLimit: Int) -> Single<Transaction> {
        let transactionInput = transactionBuilder.transferTransactionInput(to: to, value: value)

        return dataProvider.sendSingle(contractAddress: contractAddress, transactionInput: transactionInput, gasPrice: gasPrice, gasLimit: gasLimit)
                .map { [unowned self] hash in
                    Transaction(transactionHash: hash, contractAddress: contractAddress, from: self.address, to: to, value: value)
                }
                .do(onSuccess: { [weak self] transaction in
                    self?.storage.save(transactions: [transaction])
                })
    }

    func clear() {
        storage.clearTransactions()
    }

}
