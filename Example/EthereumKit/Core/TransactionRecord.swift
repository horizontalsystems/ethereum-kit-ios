import Foundation
import EthereumKit

struct TransactionRecord {
    let transactionHash: String
    let transactionIndex: Int
    let interTransactionIndex: Int
    let amount: Decimal
    let timestamp: Double

    let from: TransactionAddress
    let to: TransactionAddress

    let blockHeight: Int?
    let isError: Bool
}

struct TransactionAddress {
    let address: Address
    let mine: Bool
}
