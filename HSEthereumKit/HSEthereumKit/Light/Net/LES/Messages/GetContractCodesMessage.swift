import Foundation

class GetContractCodesMessage: IMessage {

    var requestId = 0
    var blockHash = Data()
    var key = Data()

    required init?(data: Data) {
    }

    func encoded() -> Data {
        return Data()
    }

    func toString() -> String {
        return "GET_CONTRACT_CODES []"
    }

}
