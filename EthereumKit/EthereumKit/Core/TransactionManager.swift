import RxSwift

class TransactionManager {
    private let disposeBag = DisposeBag()

    weak var delegate: ITransactionManagerDelegate?

    private let storage: ITransactionStorage
    private let transactionsProvider: ITransactionsProvider

    init(storage: ITransactionStorage, transactionsProvider: ITransactionsProvider) {
        self.storage = storage
        self.transactionsProvider = transactionsProvider
    }

    private func update(transactions: [Transaction]) {
        storage.save(transactions: transactions)

        delegate?.onUpdate(transactions: transactions.filter {
            $0.input == Data()
        })
    }

}

extension TransactionManager: ITransactionManager {

    var source: String {
        transactionsProvider.source
    }

    func refresh() {
        let lastTransactionBlockHeight = storage.lastTransactionBlockHeight ?? 0

        transactionsProvider.transactionsSingle(startBlock: lastTransactionBlockHeight + 1)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onSuccess: { [weak self] transactions in
                    self?.update(transactions: transactions)
                })
                .disposed(by: disposeBag)
    }

    func transactionsSingle(fromHash: Data?, limit: Int?) -> Single<[Transaction]> {
        storage.transactionsSingle(fromHash: fromHash, limit: limit, contractAddress: nil)
    }

    func handle(sentTransaction: Transaction) {
        update(transactions: [sentTransaction])
    }

}
