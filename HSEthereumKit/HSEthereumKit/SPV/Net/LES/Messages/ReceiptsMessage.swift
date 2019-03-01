import Foundation

class ReceiptsMessage: IMessage {

    var requestId = 0
    var bv = 0
    var receipts = [[Data]]()

    required init?(data: Data) {
    }

    func encoded() -> Data {
        return Data()
    }

    func toString() -> String {
        return "RECEIPTS []"
    }

}
