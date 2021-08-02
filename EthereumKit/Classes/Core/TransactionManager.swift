import RxSwift
import BigInt

class TransactionManager {
    private let address: Address
    private let storage: ITransactionStorage
    private let decorationManager: DecorationManager
    private let tagGenerator: TagGenerator

    private let allTransactionsSubject = PublishSubject<[FullTransaction]>()
    private let transactionsWithTagsSubject = PublishSubject<[(transaction: FullTransaction, tags: [String])]>()
    private let disposeBag = DisposeBag()

    var allTransactionsObservable: Observable<[FullTransaction]> {
        allTransactionsSubject.asObservable()
    }

    init(address: Address, storage: ITransactionStorage, transactionSyncManager: TransactionSyncManager, decorationManager: DecorationManager, tagGenerator: TagGenerator) {
        self.address = address
        self.storage = storage
        self.decorationManager = decorationManager
        self.tagGenerator = tagGenerator

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
        let decoratedTransactions = syncedTransactions.map { transaction -> FullTransaction in
            let decoratedTransaction = decorationManager.decorateFullTransaction(fullTransaction: transaction)

            if let logs = decoratedTransaction.receiptWithLogs?.logs {
                let neededLogs = logs.filter { $0.relevant }
                if logs.count > neededLogs.count {
                    storage.remove(logs: logs)
                    storage.save(logs: neededLogs)
                }
            }

            return decoratedTransaction
        }

        var transactionsWithTags = [(transaction: FullTransaction, tags: [String])]()
        for transaction in decoratedTransactions {
            let tags = tagGenerator.generate(for: transaction)
            storage.set(tags: tags)

            transactionsWithTags.append((transaction: transaction, tags: tags.map { $0.name }))
        }

        if !decoratedTransactions.isEmpty {
            allTransactionsSubject.onNext(decoratedTransactions)
            transactionsWithTagsSubject.onNext(transactionsWithTags)
        }
    }

}

extension TransactionManager {

    func etherTransferTransactionData(to: Address, value: BigUInt) -> TransactionData {
        TransactionData(
                to: to,
                value: value,
                input: Data()
        )
    }

    func transactionsObservable(tags: [[String]]) -> Observable<[FullTransaction]> {
        transactionsWithTagsSubject.asObservable()
            .map { transactions in
                transactions.compactMap { transactionsWithTags -> FullTransaction? in
                    for andTags in tags {
                        var hasTags = false

                        for tag in transactionsWithTags.tags {
                            if andTags.contains(tag) {
                                hasTags = true
                            }
                        }
                        
                        if !hasTags {
                            return nil
                        }
                    }
                    
                    return transactionsWithTags.transaction
                }
            }
            .filter { transactions in transactions.count > 0 }
    }

    func transactionsSingle(tags: [[String]], fromHash: Data?, limit: Int?) -> Single<[FullTransaction]> {
        storage
                .transactionsBeforeSingle(tags: tags, hash: fromHash, limit: limit)
                .map { [weak self] transactions in
                    if let manager = self {
                        return transactions.map {
                            manager.decorationManager.decorateFullTransaction(fullTransaction: $0)
                        }
                    }

                    return []
                }
    }

    func pendingTransactions(tags: [[String]]) -> [FullTransaction] {
        storage
                .pendingTransactions(tags: tags)
                .map { transaction in
                    decorationManager.decorateFullTransaction(fullTransaction: transaction)
                }
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
        handle(syncedTransactions: [fullTransaction])
    }

}
