import Foundation

class ProofMessage: IMessage {

    static let code = 0x19
    var code: Int { return ProofMessage.code }

    var requestId = 0
    var bv = 0
    
    var proofs = [[Data]]()

    init(data: Data) {
    }

    func encoded() -> Data {
        return Data()
    }

    func toString() -> String {
        return "PROOFS []"
    }

}
