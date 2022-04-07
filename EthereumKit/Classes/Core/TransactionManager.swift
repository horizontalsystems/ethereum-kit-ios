import RxSwift
import BigInt

class TransactionManager {
    private let storage: ITransactionStorage
    private let decorationManager: DecorationManager
    private let disposeBag = DisposeBag()

    private let fullTransactionsSubject = PublishSubject<[FullTransaction]>()
    private let fullTransactionsWithTagsSubject = PublishSubject<[(transaction: FullTransaction, tags: [String])]>()

    init(storage: ITransactionStorage, decorationManager: DecorationManager) {
        self.storage = storage
        self.decorationManager = decorationManager
    }

    private func failPendingTransactions() -> [Transaction] {
        let pendingTransactions = storage.pendingTransactions()

        guard !pendingTransactions.isEmpty else {
            return []
        }

        let nonces = Array(Set(pendingTransactions.compactMap { $0.nonce }))

        let nonPendingTransactions = storage.nonPendingTransactions(nonces: nonces)
        var processedTransactions = [Transaction]()

        for nonPendingTransaction in nonPendingTransactions {
            let duplicateTransactions = pendingTransactions.filter { $0.nonce == nonPendingTransaction.nonce }
            for transaction in duplicateTransactions {
                transaction.isFailed = true
                transaction.replacedWith = nonPendingTransaction.hash
                processedTransactions.append(transaction)
            }
        }

        storage.save(transactions: processedTransactions)

        return processedTransactions
    }

}

extension TransactionManager {

    var fullTransactionsObservable: Observable<[FullTransaction]> {
        fullTransactionsSubject.asObservable()
    }

    func etherTransferTransactionData(to: Address, value: BigUInt) -> TransactionData {
        TransactionData(
                to: to,
                value: value,
                input: Data()
        )
    }

    func fullTransactionsObservable(tags: [[String]]) -> Observable<[FullTransaction]> {
        fullTransactionsWithTagsSubject.asObservable()
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

    func fullTransactionsSingle(tags: [[String]], fromHash: Data?, limit: Int?) -> Single<[FullTransaction]> {
        Single.create { [unowned self] observer in
            let transactions = storage.transactionsBefore(tags: tags, hash: fromHash, limit: limit)
            let fullTransactions = decorationManager.decorate(transactions: transactions)
            observer(.success(fullTransactions))

            return Disposables.create()
        }
    }

    func pendingFullTransactions(tags: [[String]]) -> [FullTransaction] {
        decorationManager.decorate(transactions: storage.pendingTransactions(tags: tags))
    }

    func fullTransactions(byHashes hashes: [Data]) -> [FullTransaction] {
        decorationManager.decorate(transactions: storage.transactions(hashes: hashes))
    }

    func fullTransaction(hash: Data) -> FullTransaction? {
        storage.transaction(hash: hash).flatMap { decorationManager.decorate(transactions: [$0]).first }
    }

    func lastTransaction() -> Transaction? {
        storage.lastTransaction()
    }

    @discardableResult func handle(transactions: [Transaction]) -> [FullTransaction] {
        guard !transactions.isEmpty else {
            return []
        }

        storage.save(transactions: transactions)

        let failedTransactions = failPendingTransactions()
        let transactions = transactions + failedTransactions

        let fullTransactions = decorationManager.decorate(transactions: transactions)

        var fullTransactionsWithTags = [(transaction: FullTransaction, tags: [String])]()
        var allTags = [TransactionTag]()

        for fullTransaction in fullTransactions {
            let tags = fullTransaction.decoration.tags().map { TransactionTag(name: $0, transactionHash: fullTransaction.transaction.hash) }
            allTags.append(contentsOf: tags)
            fullTransactionsWithTags.append((transaction: fullTransaction, tags: tags.map { $0.name }))
        }

        storage.save(tags: allTags)

        fullTransactionsSubject.onNext(fullTransactions)
        fullTransactionsWithTagsSubject.onNext(fullTransactionsWithTags)

        return fullTransactions
    }

}
