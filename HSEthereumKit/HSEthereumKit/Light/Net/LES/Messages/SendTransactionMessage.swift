import Foundation

class SendTransactionMessage: IMessage {

    var requestId = 0
    var transaction: Transaction

    init(transaction: Transaction) {
        self.transaction = transaction
    }

    required init?(data: Data) {
        return nil
    }

    func encoded() -> Data {
        return Data()
    }

    func toString() -> String {
        return "SEND_TX []"
    }

}
