import Foundation

class SendTransactionMessage: IMessage {

    static let code = 0x23
    var code: Int { return SendTransactionMessage.code }

    var requestId = 0
    var transaction: Transaction

    init(transaction: Transaction) {
        self.transaction = transaction
    }

    func encoded() -> Data {
        return Data()
    }

    func toString() -> String {
        return "SEND_TX []"
    }

}
