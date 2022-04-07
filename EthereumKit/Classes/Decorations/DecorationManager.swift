import Foundation
import BigInt

class DecorationManager {
    private let userAddress: Address
    private let storage: ITransactionStorage
    private var methodDecorators = [IMethodDecorator]()
    private var eventDecorators = [IEventDecorator]()
    private var transactionDecorators = [ITransactionDecorator]()

    init(userAddress: Address, storage: ITransactionStorage) {
        self.userAddress = userAddress
        self.storage = storage
    }

    private func internalTransactionsMap(transactions: [Transaction]) -> [Data: [InternalTransaction]] {
        let internalTransactions: [InternalTransaction]

        if transactions.count > 100 {
            internalTransactions = storage.internalTransactions()
        } else {
            let hashes = transactions.map { $0.hash }
            internalTransactions = storage.internalTransactions(hashes: hashes)
        }

        var map = [Data: [InternalTransaction]]()

        for internalTransaction in internalTransactions {
            map[internalTransaction.hash] = (map[internalTransaction.hash] ?? []) + [internalTransaction]
        }

        return map
    }

    private func contractMethod(input: Data?) -> ContractMethod? {
        guard let input = input else {
            return nil
        }

        guard !input.isEmpty else {
            return EmptyMethod()
        }

        for decorator in methodDecorators {
            if let contractMethod = decorator.contractMethod(input: input) {
                return contractMethod
            }
        }

        let methodId = Data(input.prefix(4))
        var inputArguments = Data()
        if input.count > 4 {
            inputArguments = Data(input.suffix(from: 4))
        }

        return UnknownMethod(id: methodId, inputArguments: inputArguments)
    }

    private func decoration(from: Address?, to: Address?, value: BigUInt?, contractMethod: ContractMethod?, internalTransactions: [InternalTransaction] = [], eventInstances: [ContractEventInstance] = []) -> TransactionDecoration {
        for decorator in transactionDecorators {
            if let decoration = decorator.decoration(from: from, to: to, value: value, contractMethod: contractMethod, internalTransactions: internalTransactions, eventInstances: eventInstances) {
                return decoration
            }
        }

        return UnknownTransactionDecoration(
                userAddress: userAddress,
                value: value,
                internalTransactions: internalTransactions,
                eventInstances: eventInstances
        )
    }

    private func eventInstances(logs: [TransactionLog]) -> [ContractEventInstance] {
        var eventInstances = [ContractEventInstance]()

        for decorator in eventDecorators {
            eventInstances.append(contentsOf: decorator.contractEventInstances(logs: logs))
        }

        return eventInstances
    }

}

extension DecorationManager {

    func add(methodDecorator: IMethodDecorator) {
        methodDecorators.append(methodDecorator)
    }

    func add(eventDecorator: IEventDecorator) {
        eventDecorators.append(eventDecorator)
    }

    func add(transactionDecorator: ITransactionDecorator) {
        transactionDecorators.append(transactionDecorator)
    }

    func decorateTransaction(from: Address, transactionData: TransactionData) -> TransactionDecoration {
        let contractMethod = contractMethod(input: transactionData.input)
        return decoration(from: from, to: transactionData.to, value: transactionData.value, contractMethod: contractMethod)
    }

    func decorate(transactions: [Transaction]) -> [FullTransaction] {
        let internalTransactionsMap = internalTransactionsMap(transactions: transactions)
        var eventInstancesMap = [Data: [ContractEventInstance]]()

        for decorator in eventDecorators {
            for (hash, eventInstances) in decorator.contractEventInstancesMap(transactions: transactions) {
                eventInstancesMap[hash] = (eventInstancesMap[hash] ?? []) + eventInstances
            }
        }

        return transactions.map { transaction in
            let decoration = decoration(
                    from: transaction.from,
                    to: transaction.to,
                    value: transaction.value,
                    contractMethod: contractMethod(input: transaction.input),
                    internalTransactions: internalTransactionsMap[transaction.hash] ?? [],
                    eventInstances: eventInstancesMap[transaction.hash] ?? []
            )

            return FullTransaction(transaction: transaction, decoration: decoration)
        }
    }

    func decorate(fullRpcTransaction: FullRpcTransaction) -> FullTransaction {
        let transaction = fullRpcTransaction.transaction

        let decoration = decoration(
                from: transaction.from,
                to: transaction.to,
                value: transaction.value,
                contractMethod: contractMethod(input: transaction.input),
                internalTransactions: fullRpcTransaction.internalTransactions,
                eventInstances: eventInstances(logs: fullRpcTransaction.rpcTransactionReceipt.logs)
        )

        return FullTransaction(transaction: transaction, decoration: decoration)
    }

}
