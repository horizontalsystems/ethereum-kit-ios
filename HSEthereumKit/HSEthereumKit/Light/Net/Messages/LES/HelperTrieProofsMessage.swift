import Foundation

class HelperTrieProofsMessage: IMessage {

    static let code = 0x22
    var code: Int { return HelperTrieProofsMessage.code }

    var requestId = 0
    var bv = 0

    var nodes = [Data]()
    var auxData = [Data]()

    init(data: Data) {
    }

    func encoded() -> Data {
        return Data()
    }

    func toString() -> String {
        return "HELPER_TRIE_PROOFS []"
    }

}
