import Foundation

public class FullTransaction {
    public let transaction: Transaction
    public var internalTransactions = [InternalTransaction]()
    public var mainDecoration: ContractMethodDecoration? = nil
    public var eventDecorations = [ContractEventDecoration]()

    init(transaction: Transaction) {
        self.transaction = transaction
    }

    public var transactionData: TransactionData? {
        guard let to = transaction.to, let value = transaction.value, let input = transaction.input, !input.isEmpty else {
            return nil
        }

        return TransactionData(to: to, value: value, input: input)
    }

}
