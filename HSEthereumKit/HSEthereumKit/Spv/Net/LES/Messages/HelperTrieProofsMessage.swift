import Foundation

class HelperTrieProofsMessage: IMessage {

    var requestId = 0
    var bv: BInt = 0

    var nodes = [Data]()
    var auxData = [Data]()

    required init(data: Data) throws {
    }

    func encoded() -> Data {
        return Data()
    }

    func toString() -> String {
        return "HELPER_TRIE_PROOFS []"
    }

}
