import RxSwift

class TransactionManager {
    private let address: Address
    private let storage: ITransactionStorage

    private let etherTransactionsSubject = PublishSubject<[FullTransaction]>()
    private let disposeBag = DisposeBag()

    var etherTransactionsObservable: Observable<[FullTransaction]> {
        etherTransactionsSubject.asObservable()
    }

    init(address: Address, storage: ITransactionStorage, transactionSyncManager: TransactionSyncManager) {
        self.address = address
        self.storage = storage

        transactionSyncManager
                .transactionsObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(
                        onNext: { [weak self] transactions in
                            guard let manager = self else {
                                return
                            }

                            let etherTransactions = transactions.filter {
                                manager.isEtherTransferred(fullTransaction: $0)
                            }

                            guard !transactions.isEmpty else {
                                return
                            }

                            manager.etherTransactionsSubject.onNext(etherTransactions)
                        }
                )
                .disposed(by: disposeBag)
    }

    private func isEtherTransferred(fullTransaction: FullTransaction) -> Bool {
        (fullTransaction.transaction.from == address && fullTransaction.transaction.value > 0) ||
                fullTransaction.transaction.to == address ||
                fullTransaction.internalTransactions.contains {
                    $0.to == address
                }
    }

}

extension TransactionManager {

    func etherTransactionsSingle(fromHash: Data?, limit: Int?) -> Single<[FullTransaction]> {
        storage.etherTransactionsSingle(address: address, fromHash: fromHash, limit: limit)
    }

    func transactionsSingle(byHashes hashes: [Data]) -> Single<[FullTransaction]> {
        Single<[FullTransaction]>.create { [weak self] observer in
            let transactions = self?.storage.fullTransactions(byHashes: hashes) ?? []
            observer(.success(transactions))

            return Disposables.create()
        }
    }

    func transaction(hash: Data) -> FullTransaction? {
        storage.transaction(hash: hash)
    }

    func handle(sentTransaction: Transaction) {
        storage.save(transactions: [sentTransaction])

        let fullTransaction = FullTransaction(transaction: sentTransaction)

        if !isEtherTransferred(fullTransaction: fullTransaction) {
            etherTransactionsSubject.onNext([fullTransaction])
        }
    }

}
