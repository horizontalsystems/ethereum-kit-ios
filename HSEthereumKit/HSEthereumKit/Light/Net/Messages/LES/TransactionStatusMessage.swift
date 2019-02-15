import Foundation

class TransactionStatusMessage: IMessage {

    static let code = 0x25
    var code: Int { return TransactionStatusMessage.code }

    var requestId = 0
    var bv = 0
    
    var transactionStatuses = [Data: TransactionStatus]()

    init(data: Data) {
    }

    func encoded() -> Data {
        return Data()
    }

    func toString() -> String {
        return "TX_STATUS []"
    }

    enum TransactionStatus: Int {
        case unknown = 0   // transaction is unknown
        case queued = 1    // transaction is queued (not processable yet)
        case pending = 2   // transaction is pending (processable)
        case included = 3  // transaction is already included in the canonical chain. data contains an RLP-encoded [blockHash: B_32, blockNumber: P, txIndex: P] structure
        case error = 4     // transaction sending failed. data contains a text error message
    }

}
