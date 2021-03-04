import EthereumKit
import BigInt
import RxSwift

class TransactionManager {
    private let disposeBag = DisposeBag()

    private let contractAddress: Address
    private let ethereumKit: EthereumKit.Kit
    private let contractMethodFactories: Eip20ContractMethodFactories
    private var storage: ITransactionStorage
    private let address: Address

    private let transactionsSubject = PublishSubject<[Transaction]>()

    var transactionsObservable: Observable<[Transaction]> {
        transactionsSubject.asObservable()
    }

    init(contractAddress: Address, ethereumKit: EthereumKit.Kit, contractMethodFactories: Eip20ContractMethodFactories, storage: ITransactionStorage) {
        self.contractAddress = contractAddress
        self.ethereumKit = ethereumKit
        self.contractMethodFactories = contractMethodFactories
        self.storage = storage

        address = ethereumKit.receiveAddress

        ethereumKit.allTransactionsObservable
                .subscribe { [weak self] in
                    self?.processTransactions(fullTransactions: $0)
                }
                .disposed(by: disposeBag)
    }

    private func processTransactions(fullTransactions: [FullTransaction]) {
        let transactions: [TransactionCache] = fullTransactions
                .map { extractErc20Transactions(from: $0) }
                .reduce([]) { $0 + $1 }

        if !transactions.isEmpty {
            var pendingTransactions = storage.pendingTransactions

            for transaction in transactions {
                if let pendingTransaction = pendingTransactions.first(where: { $0.hash == transaction.hash }) {
                    transaction.interTransactionIndex = pendingTransaction.interTransactionIndex

                    pendingTransactions.removeAll { $0 === pendingTransaction }
                }

                storage.save(transaction: transaction)
            }

            let erc20Transactions = makeTransactions(transactions: transactions, fullTransactions: fullTransactions)
            transactionsSubject.onNext(erc20Transactions)
        }

        if let lastSyncOrder = fullTransactions.sorted(by: { a, b in a.transaction.syncOrder > b.transaction.syncOrder }).first {
            storage.lastSyncOrder = lastSyncOrder.transaction.syncOrder
        }
    }

    private func makeTransactions(transactions: [TransactionCache], fullTransactions: [FullTransaction]) -> [Transaction] {
        transactions.compactMap({ transaction in
            let fullTransaction = fullTransactions.first {
                $0.transaction.hash == transaction.hash
            }

            return fullTransaction.flatMap({
                Transaction(
                        hash: transaction.hash,
                        interTransactionIndex: transaction.interTransactionIndex,
                        transactionIndex: $0.receiptWithLogs?.receipt.transactionIndex,
                        from: transaction.from,
                        to: transaction.to,
                        value: transaction.value,
                        timestamp: transaction.timestamp,
                        isError: $0.failed,
                        type: transaction.type,
                        fullTransaction: $0
                )
            })
        })
    }

    private func extractErc20Transactions(from fullTransaction: FullTransaction) -> [TransactionCache] {
        let transaction = fullTransaction.transaction

        if let receiptWithLogs = fullTransaction.receiptWithLogs {
            return receiptWithLogs.logs.compactMap { log -> TransactionCache? in
                guard log.address == contractAddress else {
                    return nil
                }

                let event = log.getErc20Event(address: address)

                switch event {
                case .transfer(let from, let to, let value):
                    return TransactionCache(
                            hash: transaction.hash,
                            interTransactionIndex: log.logIndex,
                            logIndex: log.logIndex,
                            from: from,
                            to: to,
                            value: value,
                            timestamp: transaction.timestamp,
                            type: .transfer
                    )

                case .approve(let owner, let spender, let amount):
                    return TransactionCache(
                            hash: transaction.hash,
                            interTransactionIndex: log.logIndex,
                            logIndex: log.logIndex,
                            from: owner,
                            to: spender,
                            value: amount,
                            timestamp: transaction.timestamp,
                            type: .approve
                    )
                default: ()
                }

                return nil
            }
        } else {
            guard transaction.to == contractAddress else {
                return []
            }

            let contractMethod = contractMethodFactories.createMethod(input: fullTransaction.transaction.input)

            switch contractMethod {
            case let method as TransferMethod:
                if transaction.from == address || method.to == address {
                    return [TransactionCache(
                            hash: transaction.hash,
                            interTransactionIndex: 0,
                            logIndex: nil,
                            from: transaction.from,
                            to: method.to,
                            value: method.value,
                            timestamp: transaction.timestamp,
                            type: .transfer
                    )]
                }

            case let method as ApproveMethod:
                if transaction.from == address {
                    return [TransactionCache(
                            hash: transaction.hash,
                            interTransactionIndex: 0,
                            logIndex: nil,
                            from: transaction.from,
                            to: method.spender,
                            value: method.value,
                            timestamp: transaction.timestamp,
                            type: .approve
                    )]
                }

            default: ()
            }

            return []
        }
    }

}

extension TransactionManager: ITransactionManager {

    func transactionsSingle(from: (hash: Data, interTransactionIndex: Int)?, limit: Int?) -> Single<[Transaction]> {
        storage.transactionsSingle(from: from, limit: limit)
                .map { [weak self] transactions in
                    guard let manager = self else {
                        return []
                    }

                    let fullTransactions = manager.ethereumKit.fullTransactions(byHashes: transactions.map { $0.hash })
                    return manager.makeTransactions(transactions: transactions, fullTransactions: fullTransactions)
                }
    }

    func pendingTransactions() -> [Transaction] {
        let transactions = storage.pendingTransactions
        let fullTransactions = ethereumKit.fullTransactions(byHashes: transactions.map { $0.hash })

        return makeTransactions(transactions: transactions, fullTransactions: fullTransactions)
    }

    func transferTransactionData(to: Address, value: BigUInt) -> TransactionData {
        TransactionData(
                to: contractAddress,
                value: BigUInt.zero,
                input: TransferMethod(to: to, value: value).encodedABI()
        )
    }

    func sync() {
        let fullTransactions = ethereumKit.fullTransactions(fromSyncOrder: storage.lastSyncOrder)

        processTransactions(fullTransactions: fullTransactions)
    }

}
