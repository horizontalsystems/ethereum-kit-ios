class DecorationManager {
    private var decorators = [IDecorator]()

    func add(decorator: IDecorator) {
        decorators.append(decorator)
    }

    private func decorateMain(fullTransaction: FullTransaction) {
        guard fullTransaction.mainDecoration == nil else {
            return
        }

        guard let transactionData = fullTransaction.transactionData else {
            return
        }

        let input = transactionData.input

        let methodId = Data(input.prefix(4))
        var inputArguments = Data()
        if input.count > 4 {
            inputArguments = Data(input.suffix(from: 4))
        }

        fullTransaction.mainDecoration = UnknownMethodDecoration(methodId: methodId, inputArguments: inputArguments)
    }

    func decorateTransaction(transactionData: TransactionData) -> ContractMethodDecoration? {
        guard !transactionData.input.isEmpty else {
            return nil
        }

        for decorator in decorators {
            if let decoration = decorator.decorate(transactionData: transactionData) {
                return decoration
            }
        }

        return nil
    }

    func decorate(transactions: [Transaction]) -> [FullTransaction] {
        let fullTransactions = transactions.map { FullTransaction(transaction: $0) }

        let map = fullTransactions.reduce(into: [Data: FullTransaction]()) { $0[$1.transaction.hash] = $1 }
        for decorator in decorators {
            decorator.decorate(fullTransactionMap: map)
        }

        for fullTransaction in fullTransactions {
            decorateMain(fullTransaction: fullTransaction)
        }

        return fullTransactions
    }

    func decorate(fullRpcTransaction: FullRpcTransaction) -> FullTransaction {
        let fullTransaction = FullTransaction(transaction: fullRpcTransaction.transaction)

        for decorator in decorators {
            decorator.decorate(fullTransaction: fullTransaction, fullRpcTransaction: fullRpcTransaction)
        }

        decorateMain(fullTransaction: fullTransaction)

        return fullTransaction

    }

}
