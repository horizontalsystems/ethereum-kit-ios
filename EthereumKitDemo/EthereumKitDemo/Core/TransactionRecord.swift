import Foundation

struct TransactionRecord {
    let transactionHash: String
    let index: Int
    let amount: Decimal
    let timestamp: Double

    let from: TransactionAddress
    let to: TransactionAddress

    let blockHeight: Int?
}

struct TransactionAddress {
    let address: String
    let mine: Bool
}
