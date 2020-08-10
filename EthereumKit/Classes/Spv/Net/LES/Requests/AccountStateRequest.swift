class AccountStateRequest {
    let address: Address
    let blockHeader: BlockHeader

    init(address: Address, blockHeader: BlockHeader) {
        self.address = address
        self.blockHeader = blockHeader
    }

    func accountState(proofsMessage: ProofsMessage) throws -> AccountState {
        guard var lastNode = proofsMessage.nodes.last else {
            throw ProofError.noNodes
        }

        guard lastNode.nodeType == TrieNode.NodeType.LEAF,
              var path = lastNode.getPath(element: nil) else {
            throw ProofError.stateNodeNotFound
        }

        let rlpState = try RLP.decode(input: lastNode.elements[1]).listValue()
        guard rlpState.count == 4 else {
            throw ProofError.wrongState
        }

        let nonce = try rlpState[0].intValue()
        let balance = try rlpState[1].bigIntValue()
        let storageRoot = rlpState[2].dataValue
        let codeHash = rlpState[3].dataValue

        var lastNodeKey = lastNode.hash

        for i in stride(from: proofsMessage.nodes.count - 2, through: 0, by: -1) {
            lastNode = proofsMessage.nodes[i]

            guard let partialPath = lastNode.getPath(element: lastNodeKey) else {
                throw ProofError.nodesNotInterconnected
            }

            path = partialPath + path
            lastNodeKey = lastNode.hash
        }

        let addressHash = CryptoUtils.shared.sha3(address.raw)

        guard addressHash.hex == path else {
            throw ProofError.pathDoesNotMatchAddressHash
        }

        guard blockHeader.stateRoot == lastNodeKey else {
            throw ProofError.rootHashDoesNotMatchStateRoot
        }

        return AccountState(address: address, nonce: nonce, balance: balance, storageHash: storageRoot, codeHash: codeHash)
    }
}

extension AccountStateRequest {

    enum ProofError: Error {
        case noNodes
        case stateNodeNotFound
        case nodesNotInterconnected
        case pathDoesNotMatchAddressHash
        case rootHashDoesNotMatchStateRoot
        case wrongState
    }

}
