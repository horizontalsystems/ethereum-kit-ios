import RxSwift

class TransactionManager {
    private let address: Address
    private let storage: ITransactionStorage

    private let etherTransactionsSubject = PublishSubject<[FullTransaction]>()
    private let allTransactionsSubject = PublishSubject<[FullTransaction]>()
    private let disposeBag = DisposeBag()

    var etherTransactionsObservable: Observable<[FullTransaction]> {
        etherTransactionsSubject.asObservable()
    }

    var allTransactionsObservable: Observable<[FullTransaction]> {
        allTransactionsSubject.asObservable()
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

                            if !transactions.isEmpty {
                                manager.allTransactionsSubject.onNext(transactions)
                            }

                            let etherTransactions = transactions.filter {
                                manager.hasEtherTransferred(fullTransaction: $0)
                            }

                            if !etherTransactions.isEmpty {
                                manager.etherTransactionsSubject.onNext(etherTransactions)
                            }
                        }
                )
                .disposed(by: disposeBag)
    }

    private func hasEtherTransferred(fullTransaction: FullTransaction) -> Bool {
        (fullTransaction.transaction.from == address && fullTransaction.transaction.value > 0) ||
                fullTransaction.transaction.to == address ||
                fullTransaction.internalTransactions.contains {
                    $0.to == address
                }
    }

}

extension TransactionManager {

    func etherTransactionsSingle(fromHash: Data?, limit: Int?) -> Single<[FullTransaction]> {
        storage.etherTransactionsBeforeSingle(address: address, hash: fromHash, limit: limit)
    }

    func transactions(byHashes hashes: [Data]) -> [FullTransaction] {
        storage.fullTransactions(byHashes: hashes)
    }

    func transaction(hash: Data) -> FullTransaction? {
        storage.transaction(hash: hash)
    }

    func handle(sentTransaction: Transaction) {
        storage.save(transactions: [sentTransaction])

        let fullTransaction = FullTransaction(transaction: sentTransaction)
        allTransactionsSubject.onNext([fullTransaction])

        if !hasEtherTransferred(fullTransaction: fullTransaction) {
            etherTransactionsSubject.onNext([fullTransaction])
        }
    }

    func transactions(fromHash: Data?) -> [FullTransaction] {
        storage.fullTransactionsAfter(hash: fromHash)
    }

}
