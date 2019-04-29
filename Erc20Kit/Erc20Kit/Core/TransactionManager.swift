import RxSwift
import BigInt

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

}

extension TransactionManager: ITransactionManager {

    var lastTransactionBlockHeight: Int? {
        return storage.lastTransactionBlockHeight
    }

    func transactionsSingle(from: (hash: Data, index: Int)?, limit: Int?) -> Single<[Transaction]> {
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

        dataProvider.getTransactions(contractAddress: contractAddress, address: address, from: lastTransactionBlockHeight + 1, to: lastBlockHeight)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onSuccess: { [weak self] transactions in
                    self?.storage.save(transactions: transactions)
                    self?.delegate?.onSyncSuccess(transactions: transactions)
                }, onError: { error in
                    self.delegate?.onSyncTransactionsError()
                })
                .disposed(by: disposeBag)
    }

    func clear() {
        storage.clearTransactions()
    }

}
