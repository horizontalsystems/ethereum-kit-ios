import Foundation

class ContractCodesMessage: IMessage {

    var requestId = 0
    var bv = 0
    var contractCodes = [Data]()

    required init?(data: Data) {
        let rlp = RLP.decode(input: data)

        guard rlp.isList() && rlp.listValue.count > 0 else {
            return nil
        }
    }

    func encoded() -> Data {
        return Data()
    }

    func toString() -> String {
        return "CONTRACT_CODES []"
    }

}
