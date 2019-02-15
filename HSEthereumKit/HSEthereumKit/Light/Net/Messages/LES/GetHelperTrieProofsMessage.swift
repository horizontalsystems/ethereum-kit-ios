import Foundation

class GetHelperTrieProofsMessage: IMessage {

    static let code = 0x21
    var code: Int { return GetHelperTrieProofsMessage.code }

    var requestId = 0
    var proofRequests = [ProofRequest]()
    var auxData = [Data]()

    init(data: Data) {
    }

    func encoded() -> Data {
        return Data()
    }

    func toString() -> String {
        return "HELPER_TRIE_PROOFS []"
    }

    class ProofRequest {

        let subType: Int // 0 (CHT) or 1 (BloomBits)
        let sectionIdx: Int
        let key: Data
        let fromLevel: Int?
        let auxReq: Int?

        init(subType: Int, sectionIdx: Int, key: Data, fromLevel: Int? = nil, auxReq: Int? = nil) {
            self.subType = subType
            self.sectionIdx = sectionIdx
            self.key = key
            self.fromLevel = fromLevel
            self.auxReq = auxReq
        }

    }

}
