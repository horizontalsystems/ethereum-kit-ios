import Foundation

class ReceiptsMessage: IMessage {

    var requestId = 0
    var bv: BInt = 0
    var receipts = [[Data]]()

    required init(data: Data) throws {
    }

    func encoded() -> Data {
        return Data()
    }

    func toString() -> String {
        return "RECEIPTS []"
    }

}
