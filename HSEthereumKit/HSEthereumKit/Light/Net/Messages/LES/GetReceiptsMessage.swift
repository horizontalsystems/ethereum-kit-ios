import Foundation

class GetReceiptsMessage: IMessage {

    static let code = 0x16
    var code: Int { return GetReceiptsMessage.code }

    var requestId = 0
    var blockHashes = [Data]()

    init(data: Data) {
    }

    func encoded() -> Data {
        return Data()
    }

    func toString() -> String {
        return "GET_RECEIPTS []"
    }

}
