class DecorationManager {
    private let address: Address
    private var decorators = [IDecorator]()

    init(address: Address) {
        self.address = address
    }

    func add(decorator: IDecorator) {
        decorators.append(decorator)
    }

    func decorate(transactionData: TransactionData) -> TransactionDecoration? {
        guard !transactionData.input.isEmpty else {
            return .transfer(from: address, to: transactionData.to, value: transactionData.value)
        }

        for decorator in decorators {
            if let decoration = decorator.decorate(transactionData: transactionData, fullTransaction: nil) {
                return decoration
            }
        }

        return nil
    }

    func decorate(fullTransaction: FullTransaction) -> TransactionDecoration? {
        let transaction = fullTransaction.transaction
        let transactionData = TransactionData(to: transaction.to!, value: transaction.value, input: transaction.input)

        guard !transactionData.input.isEmpty else {
            return .transfer(from: address, to: transactionData.to, value: transactionData.value)
        }

        for decorator in decorators {
            if let decoration = decorator.decorate(transactionData: transactionData, fullTransaction: fullTransaction) {
                return decoration
            }
        }

        return nil
    }

}
