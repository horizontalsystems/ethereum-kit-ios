class LESPeerRequestHolder {
    private var blockHeaderRequests: [Int: BlockHeaderRequest] = [:]
    private var accountStateRequests: [Int: AccountStateRequest] = [:]

    func set(blockHeaderRequest: BlockHeaderRequest, id: Int) {
        blockHeaderRequests[id] = blockHeaderRequest
    }

    func removeBlockHeaderRequest(id: Int) -> BlockHeaderRequest? {
        return blockHeaderRequests.removeValue(forKey: id)
    }

    func set(accountStateRequest: AccountStateRequest, id: Int) {
        accountStateRequests[id] = accountStateRequest
    }

    func removeAccountStateRequest(id: Int) -> AccountStateRequest? {
        return accountStateRequests.removeValue(forKey: id)
    }
}
