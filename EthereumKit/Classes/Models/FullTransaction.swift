import Foundation

public struct FullTransaction {
    public let transaction: Transaction
    public let receiptWithLogs: ReceiptWithLogs?
    public let internalTransactions: [InternalTransaction]
    public var mainDecoration: ContractMethodDecoration? = nil
    public var eventDecorations = [ContractEventDecoration]()
    public let replacedWith: Data?

    init(transaction: Transaction, receiptWithLogs: ReceiptWithLogs? = nil, internalTransactions: [InternalTransaction] = [], replacedWith: Data? = nil) {
        self.transaction = transaction
        self.receiptWithLogs = receiptWithLogs
        self.internalTransactions = internalTransactions
        self.replacedWith = replacedWith
    }

    public var failed: Bool {
        if let receipt = receiptWithLogs?.receipt {
            if let status = receipt.status {
                return status == 0
            } else {
                return transaction.gasLimit == receipt.gasUsed
            }
        } else {
            return replacedWith != nil
        }
    }

}
