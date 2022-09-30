import RxSwift
import BigInt

class TransactionManager {
    private let userAddress: Address
    private let storage: TransactionStorage
    private let decorationManager: DecorationManager
    private let blockchain: IBlockchain
    private let transactionProvider: ITransactionProvider
    private let disposeBag = DisposeBag()

    private let fullTransactionsSubject = PublishSubject<([FullTransaction], Bool)>()
    private let fullTransactionsWithTagsSubject = PublishSubject<[(transaction: FullTransaction, tags: [TransactionTag])]>()

    init(userAddress: Address, storage: TransactionStorage, decorationManager: DecorationManager, blockchain: IBlockchain, transactionProvider: ITransactionProvider) {
        self.userAddress = userAddress
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

        let nonPendingTransactions = storage.nonPendingTransactions(from: userAddress, nonces: nonces)
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

    var fullTransactionsObservable: Observable<([FullTransaction], Bool)> {
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
                .flatMap { [weak self] rpcTransaction -> Single<FullRpcTransaction> in
                    guard let strongSelf = self else {
                        throw Kit.KitError.weakReference
                    }

                    if let blockNumber = rpcTransaction.blockNumber {
                        return Single.zip(
                                        strongSelf.blockchain.transactionReceiptSingle(transactionHash: hash),
                                        strongSelf.blockchain.getBlock(blockNumber: blockNumber),
                                        strongSelf.transactionProvider.internalTransactionsSingle(transactionHash: hash)
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
                .flatMap { [weak self] fullRpcTransaction in
                    guard let strongSelf = self else {
                        throw Kit.KitError.weakReference
                    }

                    return Single.just(try strongSelf.decorationManager.decorate(fullRpcTransaction: fullRpcTransaction))
                }
    }

    func fullTransactionsObservable(tagQueries: [TransactionTagQuery]) -> Observable<[FullTransaction]> {
        fullTransactionsWithTagsSubject.asObservable()
            .map { transactionsWithTags in
                transactionsWithTags.compactMap { (transaction: FullTransaction, tags: [TransactionTag]) -> FullTransaction? in
                    for tagQuery in tagQueries {
                        for tag in tags {
                            if tag.conforms(tagQuery: tagQuery) {
                                return transaction
                            }
                        }
                    }

                    return nil
                }
            }
            .filter { transactions in transactions.count > 0 }
    }

    func fullTransactionsSingle(tagQueries: [TransactionTagQuery], fromHash: Data?, limit: Int?) -> Single<[FullTransaction]> {
        Single.create { [weak self] observer in
            guard let strongSelf = self else {
                observer(.error(Kit.KitError.weakReference))
                return Disposables.create()
            }

            let transactions = strongSelf.storage.transactionsBefore(tagQueries: tagQueries, hash: fromHash, limit: limit)
            let fullTransactions = strongSelf.decorationManager.decorate(transactions: transactions)
            observer(.success(fullTransactions))

            return Disposables.create()
        }
    }

    func pendingFullTransactions(tagQueries: [TransactionTagQuery]) -> [FullTransaction] {
        decorationManager.decorate(transactions: storage.pendingTransactions(tagQueries: tagQueries))
    }

    func fullTransactions(byHashes hashes: [Data]) -> [FullTransaction] {
        decorationManager.decorate(transactions: storage.transactions(hashes: hashes))
    }

    func fullTransaction(hash: Data) -> FullTransaction? {
        storage.transaction(hash: hash).flatMap { decorationManager.decorate(transactions: [$0]).first }
    }

    @discardableResult func handle(transactions: [Transaction], initial: Bool = false) -> [FullTransaction] {
        guard !transactions.isEmpty else {
            return []
        }

        storage.save(transactions: transactions)

        let failedTransactions = failPendingTransactions()
        let transactions = transactions + failedTransactions

        let fullTransactions = decorationManager.decorate(transactions: transactions)

        var fullTransactionsWithTags = [(transaction: FullTransaction, tags: [TransactionTag])]()
        var tagRecords = [TransactionTagRecord]()

        for fullTransaction in fullTransactions {
            let tags = fullTransaction.decoration.tags()
            tagRecords.append(contentsOf: tags.map { TransactionTagRecord(transactionHash: fullTransaction.transaction.hash, tag: $0) })
            fullTransactionsWithTags.append((transaction: fullTransaction, tags: tags))
        }

        storage.save(tags: tagRecords)

        fullTransactionsSubject.onNext((fullTransactions, initial))
        fullTransactionsWithTagsSubject.onNext(fullTransactionsWithTags)

        return fullTransactions
    }

    func tagTokens() -> [TagToken] {
        do {
            return try storage.tagTokens()
        } catch {
            print("Failed to fetch tag tokens: \(error)")
            return []
        }
    }

}
