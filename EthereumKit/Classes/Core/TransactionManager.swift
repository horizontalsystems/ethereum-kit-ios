import RxSwift
import BigInt

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
                            self?.handle(syncedTransactions: transactions)
                        }
                )
                .disposed(by: disposeBag)
    }

    private func handle(syncedTransactions: [FullTransaction]) {
        if !syncedTransactions.isEmpty {
            allTransactionsSubject.onNext(syncedTransactions)
        }

        let etherTransactions = syncedTransactions.filter {
            hasEtherTransferred(fullTransaction: $0)
        }

        if !etherTransactions.isEmpty {
            etherTransactionsSubject.onNext(etherTransactions)
        }
    }

    private func hasEtherTransferred(fullTransaction: FullTransaction) -> Bool {
        (fullTransaction.transaction.from == address && fullTransaction.transaction.value > 0) ||
                fullTransaction.transaction.to == address ||
                fullTransaction.internalTransactions.contains {
                    $0.to == address
                }
    }

    func etherTransferTransactionData(to: Address, value: BigUInt) -> TransactionData {
        TransactionData(
                to: to,
                value: value,
                input: Data()
        )
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
        storage.save(transaction: sentTransaction)

        let fullTransaction = FullTransaction(transaction: sentTransaction)
        allTransactionsSubject.onNext([fullTransaction])

        if hasEtherTransferred(fullTransaction: fullTransaction) {
            etherTransactionsSubject.onNext([fullTransaction])
        }
    }

    func transactions(fromSyncOrder: Int?) -> [FullTransaction] {
        storage.fullTransactionsAfter(syncOrder: fromSyncOrder)
    }

}
