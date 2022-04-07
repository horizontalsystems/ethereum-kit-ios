import Foundation

public class FullTransaction {
    public let transaction: Transaction
    public let decoration: TransactionDecoration

    init(transaction: Transaction, decoration: TransactionDecoration) {
        self.transaction = transaction
        self.decoration = decoration
    }

}
