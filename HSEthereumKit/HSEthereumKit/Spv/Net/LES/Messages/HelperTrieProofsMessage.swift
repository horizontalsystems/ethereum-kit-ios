class HelperTrieProofsMessage: IInMessage {
    var requestId = 0
    var bv: Int = 0

    required init(data: Data) throws {
    }

    func toString() -> String {
        return "HELPER_TRIE_PROOFS []"
    }

}
