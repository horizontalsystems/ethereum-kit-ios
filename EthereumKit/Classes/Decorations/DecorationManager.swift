class DecorationManager {
    private let address: Address
    private var decorators = [IDecorator]()

    init(address: Address) {
        self.address = address
    }

    func add(decorator: IDecorator) {
        decorators.append(decorator)
    }

    func decorateTransaction(transactionData: TransactionData) -> ContractMethodDecoration? {
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

        guard let to = transaction.to else {
            return fullTransaction
        }

        let transactionData = TransactionData(to: to, value: transaction.value, input: transaction.input)

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

        if fullTransaction.mainDecoration == nil {
            let methodId = Data(fullTransaction.transaction.input.prefix(4))
            let inputArguments = Data(fullTransaction.transaction.input.suffix(from: 4))

            fullTransaction.mainDecoration = UnknownMethodDecoration(methodId: methodId, inputArguments: inputArguments)
        }

        return fullTransaction
    }

}
