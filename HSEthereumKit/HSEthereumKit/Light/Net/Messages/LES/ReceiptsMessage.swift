import Foundation

class ReceiptsMessage: IMessage {

    static let code = 0x17
    var code: Int { return ReceiptsMessage.code }

    var requestId = 0
    var bv = 0
    
    var receipts = [[Data]]()

    init(data: Data) {
    }

    func encoded() -> Data {
        return Data()
    }

    func toString() -> String {
        return "RECEIPTS []"
    }

}
