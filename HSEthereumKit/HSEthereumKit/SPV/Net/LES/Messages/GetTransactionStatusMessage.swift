import Foundation

class GetTransactionStatusMessage: IMessage {

    var requestId = 0
    var transactionHashes = [Data]()

    required init?(data: Data) {
    }

    func encoded() -> Data {
        return Data()
    }

    func toString() -> String {
        return "GET_TX_STATUS []"
    }

}
