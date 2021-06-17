import Foundation
import EthereumKit

struct TransactionRecord {
    let transactionHash: String
    let transactionHashData: Data
    let transactionIndex: Int
    let interTransactionIndex: Int
    let amount: Decimal
    let timestamp: Int

    let from: TransactionAddress
    let to: TransactionAddress

    let blockHeight: Int?
    let isError: Bool
    let type: String

    let mainDecoration: TransactionDecoration?
    let eventsDecorations: [ContractEventDecoration]
}

struct TransactionAddress {
    let address: Address?
    let mine: Bool
}
