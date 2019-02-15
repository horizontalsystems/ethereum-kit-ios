import Foundation

class GetTransactionStatusMessage: IMessage {

    static let code = 0x24
    var code: Int { return GetTransactionStatusMessage.code }

    var requestId = 0
    var transactionHashes = [Data]()

    init(data: Data) {
    }

    func encoded() -> Data {
        return Data()
    }

    func toString() -> String {
        return "GET_TX_STATUS []"
    }

}
