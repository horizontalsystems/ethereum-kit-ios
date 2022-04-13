import RxSwift
import BigInt

class TransactionManager {
    private let storage: ITransactionStorage
    private let decorationManager: DecorationManager
    private let blockchain: IBlockchain
    private let transactionProvider: ITransactionProvider
    private let disposeBag = DisposeBag()

    private let fullTransactionsSubject = PublishSubject<[FullTransaction]>()
    private let fullTransactionsWithTagsSubject = PublishSubject<[(transaction: FullTransaction, tags: [String])]>()

    init(storage: ITransactionStorage, decorationManager: DecorationManager, blockchain: IBlockchain, transactionProvider: ITransactionProvider) {
        self.storage = storage
        self.decorationManager = decorationManager
        self.blockchain = blockchain
        self.transactionProvider = transactionProvider
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

    func fullTransactionSingle(hash: Data) -> Single<FullTransaction> {
        blockchain.transactionSingle(transactionHash: hash)
                .flatMap { [unowned self] rpcTransaction -> Single<FullRpcTransaction> in
                    if let blockNumber = rpcTransaction.blockNumber {
                        return Single.zip(
                                blockchain.transactionReceiptSingle(transactionHash: hash),
                                blockchain.getBlock(blockNumber: blockNumber),
                                transactionProvider.internalTransactionsSingle(transactionHash: hash)
                        )
                                .map { rpcTransactionReceipt, rpcBlock, providerInternalTransactions in
                                    FullRpcTransaction(
                                            rpcTransaction: rpcTransaction,
                                            rpcTransactionReceipt: rpcTransactionReceipt,
                                            rpcBlock: rpcBlock,
                                            providerInternalTransactions: providerInternalTransactions
                                    )
                                }
                    } else {
                        return Single.just(FullRpcTransaction(rpcTransaction: rpcTransaction))
                    }
                }
                .map { [unowned self] fullRpcTransaction in
                    try decorationManager.decorate(fullRpcTransaction: fullRpcTransaction)
                }
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
