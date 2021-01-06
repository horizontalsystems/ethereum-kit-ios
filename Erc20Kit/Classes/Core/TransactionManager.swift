import EthereumKit
import BigInt
import RxSwift

class TransactionManager {
    private let disposeBag = DisposeBag()

    private let contractAddress: Address
    private let ethereumKit: EthereumKit.Kit
    private let contractMethodFactories: ContractMethodFactories
    private let storage: ITransactionStorage
    private let address: Address

    private let transactionsSubject = PublishSubject<[Transaction]>()

    var transactionsObservable: Observable<[Transaction]> {
        transactionsSubject.asObservable()
    }

    init(contractAddress: Address, ethereumKit: EthereumKit.Kit, contractMethodFactories: ContractMethodFactories, storage: ITransactionStorage) {
        self.contractAddress = contractAddress
        self.ethereumKit = ethereumKit
        self.contractMethodFactories = contractMethodFactories
        self.storage = storage

        address = ethereumKit.receiveAddress

        ethereumKit.allTransactionsObservable
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe { [weak self] in
                    self?.processTransactions(fullTransactions: $0)
                }
                .disposed(by: disposeBag)
    }

    private func processTransactions(fullTransactions: [FullTransaction]) {
        let records: [TransactionRecord] = fullTransactions
                .map { extractErc20TransactionRecords(from: $0) }
                .reduce([]) { $0 + $1 }

        guard !records.isEmpty else {
            return
        }

        var pendingTransactionRecords = storage.pendingTransactions

        for transaction in records {
            if let pendingTransactionRecord = pendingTransactionRecords.first(where: { $0.hash == transaction.hash }) {
                transaction.interTransactionIndex = pendingTransactionRecord.interTransactionIndex

                pendingTransactionRecords.removeAll { $0 === pendingTransactionRecord }
            }

            storage.save(transaction: transaction)
        }

        let erc20Transactions = makeTransactions(records: records, fullTransactions: fullTransactions)
        transactionsSubject.onNext(erc20Transactions)
    }

    private func makeTransactions(records: [TransactionRecord], fullTransactions: [FullTransaction]) -> [Transaction] {
        records.compactMap({ transactionRecord in
            let fullTransaction = fullTransactions.first {
                $0.transaction.hash == transactionRecord.hash
            }

            return fullTransaction.flatMap({
                Transaction(
                        hash: transactionRecord.hash,
                        interTransactionIndex: transactionRecord.interTransactionIndex,
                        transactionIndex: $0.receiptWithLogs?.receipt.transactionIndex,
                        from: transactionRecord.from,
                        to: transactionRecord.to,
                        value: transactionRecord.value,
                        timestamp: transactionRecord.timestamp,
                        isError: $0.failed,
                        type: transactionRecord.type,
                        fullTransaction: $0
                )
            })
        })
    }

    private func extractErc20TransactionRecords(from fullTransaction: FullTransaction) -> [TransactionRecord] {
        let transaction = fullTransaction.transaction

        if let receiptWithLogs = fullTransaction.receiptWithLogs {
            return receiptWithLogs.logs.compactMap { log -> TransactionRecord? in
                guard log.address == contractAddress else {
                    return nil
                }

                let event = log.getErc20Event(address: address)

                switch event {
                case .transfer(let from, let to, let value):
                    return TransactionRecord(
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
                    return TransactionRecord(
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
                    return [TransactionRecord(
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
                    return [TransactionRecord(
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
                .map { [weak self] records in
                    guard let manager = self else {
                        return []
                    }

                    let fullTransactions = manager.ethereumKit.fullTransactions(byHashes: records.map { $0.hash })
                    return manager.makeTransactions(records: records, fullTransactions: fullTransactions)
                }
    }

    func pendingTransactions() -> [Transaction] {
        let records = storage.pendingTransactions
        let fullTransactions = ethereumKit.fullTransactions(byHashes: records.map { $0.hash })

        return makeTransactions(records: records, fullTransactions: fullTransactions)
    }

    func transferTransactionData(to: Address, value: BigUInt) -> TransactionData {
        TransactionData(
                to: contractAddress,
                value: BigUInt.zero,
                input: TransferMethod(to: to, value: value).encodedABI()
        )
    }

    func sync() {
        let lastTransaction = storage.lastTransaction
        let fullTransactions = ethereumKit.fullTransactions(fromHash: lastTransaction?.hash)

        processTransactions(fullTransactions: fullTransactions)
    }

}

enum Erc20LogEvent {
    static let transferSignature = ContractEvent(name: "Transfer", arguments: [.address, .address, .uint256]).signature
    static let approvalSignature = ContractEvent(name: "Approval", arguments: [.address, .address, .uint256]).signature

    case transfer(from: Address, to: Address, value: BigUInt)
    case approve(owner: Address, spender: Address, value: BigUInt)
}

extension TransactionLog {

    func getErc20Event(address: Address) -> Erc20LogEvent? {
        guard topics.count == 3 else {
            return nil
        }

        let signature = topics[0]
        let firstParam = Address(raw: topics[1])
        let secondParam = Address(raw: topics[2])

        if signature == Erc20LogEvent.transferSignature && (firstParam == address || secondParam == address) {
            return .transfer(from: firstParam, to: secondParam, value: BigUInt(data))
        }

        if signature == Erc20LogEvent.approvalSignature && firstParam == address {
            return .approve(owner: firstParam, spender: secondParam, value: BigUInt(data))
        }

        return nil
    }

}

extension Array {

    subscript (safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }

}