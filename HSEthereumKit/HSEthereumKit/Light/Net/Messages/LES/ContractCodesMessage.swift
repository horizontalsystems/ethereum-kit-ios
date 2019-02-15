import Foundation

class ContractCodesMessage: IMessage {

    static let code = 0x1b
    var code: Int { return ContractCodesMessage.code }

    var requestId = 0
    var bv = 0
  
    var contractCodes = [Data]()

    init(data: Data) {
    }

    func encoded() -> Data {
        return Data()
    }

    func toString() -> String {
        return "CONTRACT_CODES []"
    }

}
