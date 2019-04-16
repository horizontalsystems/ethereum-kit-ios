import Foundation

struct TransactionRecord {
    let transactionHash: String
    let blockHeight: Int?
    let amount: Decimal
    let timestamp: Double

    let from: TransactionAddress
    let to: TransactionAddress
}

struct TransactionAddress {
    let address: String
    let mine: Bool
}
