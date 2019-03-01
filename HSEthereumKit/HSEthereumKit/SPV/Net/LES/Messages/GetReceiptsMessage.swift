import Foundation

class GetReceiptsMessage: IMessage {

    var requestId = 0
    var blockHashes = [Data]()

    required init?(data: Data) {
    }

    func encoded() -> Data {
        return Data()
    }

    func toString() -> String {
        return "GET_RECEIPTS []"
    }

}
