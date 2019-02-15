import Foundation

class GetContractCodesMessage: IMessage {

    static let code = 0x1a
    var code: Int { return GetContractCodesMessage.code }

    var requestId = 0
    var blockHash = Data()
    var key = Data()

    init(data: Data) {
    }

    func encoded() -> Data {
        return Data()
    }

    func toString() -> String {
        return "GET_CONTRACT_CODES []"
    }

}
