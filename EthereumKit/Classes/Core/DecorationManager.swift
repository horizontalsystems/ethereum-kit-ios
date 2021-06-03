class DecorationManager {
    private let address: Address
    private var decorators = [IDecorator]()

    init(address: Address) {
        self.address = address
    }

    func add(decorator: IDecorator) {
        decorators.append(decorator)
    }

    func decorateTransaction(transactionData: TransactionData) -> TransactionDecoration? {
        guard !transactionData.input.isEmpty else {
            return nil
        }

        for decorator in decorators {
            if let decoration = decorator.decorate(transactionData: transactionData, fullTransaction: nil) {
                return decoration
            }
        }

        return nil
    }

    func decorateFullTransaction(fullTransaction: FullTransaction) -> FullTransaction {
        let transaction = fullTransaction.transaction
        let transactionData = TransactionData(to: transaction.to!, value: transaction.value, input: transaction.input)

        guard !transactionData.input.isEmpty else {
            return fullTransaction
        }

        var fullTransaction = fullTransaction

        for decorator in decorators {
            if let decoration = decorator.decorate(transactionData: transactionData, fullTransaction: fullTransaction) {
                fullTransaction.mainDecoration = decoration
            }

            if let logs = fullTransaction.receiptWithLogs?.logs {
                fullTransaction.eventDecorations.append(contentsOf: decorator.decorate(logs: logs))
            }
        }

        return fullTransaction
    }

}
