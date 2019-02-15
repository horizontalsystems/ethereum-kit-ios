import Foundation

class GetProofsMessage: IMessage {

    static let code = 0x18
    var code: Int { return GetProofsMessage.code }

    var requestId = 0
    var proofRequests = [ProofRequest]()

    init(data: Data) {
    }

    func encoded() -> Data {
        return Data()
    }

    func toString() -> String {
        return "GET_PROOFS []"
    }

    class ProofRequest {

        let blockHash: Data
        let key: Data
        let key2: Data
        let fromLevel: Int?

        init(blockHash: Data, key: Data, key2: Data, fromLevel: Int? = nil) {
            self.blockHash = blockHash
            self.key = key
            self.key2 = key2
            self.fromLevel = fromLevel
        }

    }

}
