import Foundation

class ProofsMessage: IMessage {

    enum ProofError: Error {
        case noNodes
        case stateNodeNotFound
        case nodesNotInterconnected
        case pathDoesNotMatchAddressHash
        case rootHashDoesNotMatchStateRoot
        case wrongState
    }

    let requestId: Int
    let bv: Int
    var nodes: [TrieNode]

    required init(data: Data) throws {
        let rlpList = try RLP.decode(input: data).listValue()

        guard rlpList.count > 2 else {
            throw MessageDecodeError.notEnoughFields
        }

        requestId = try rlpList[0].intValue()
        bv = try rlpList[1].intValue()

        nodes = [TrieNode]()
        for rlpNode in try rlpList[2].listValue() {
            nodes.append(try TrieNode(rlp: rlpNode))
        }
    }

    func getValidatedState(stateRoot: Data, address: Data) throws -> AccountState {
        guard var lastNode = nodes.last else {
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
        let balance = Balance(wei: try rlpState[1].bIntValue())
        let storageRoot = rlpState[2].dataValue
        let codeHash = rlpState[3].dataValue

        var lastNodeKey = lastNode.hash

        for i in stride(from: nodes.count - 2, through: 0, by: -1) {
            lastNode = nodes[i]

            guard let partialPath = lastNode.getPath(element: lastNodeKey) else {
                throw ProofError.nodesNotInterconnected
            }

            path = partialPath + path
            lastNodeKey = lastNode.hash
        }

        let addressHash = CryptoUtils.shared.sha3(address)

        guard addressHash.toHexString() == path else {
            throw ProofError.pathDoesNotMatchAddressHash
        }

        guard stateRoot == lastNodeKey else {
            throw ProofError.rootHashDoesNotMatchStateRoot
        }

        return AccountState(address: address, nonce: nonce, balance: balance, storageHash: storageRoot, codeHash: codeHash)
    }

    func encoded() -> Data {
        return Data()
    }

    func toString() -> String {
        return "PROOFS [requestId: \(requestId); bv: \(bv); headers: [\(nodes.map{ $0.toString() }.joined(separator: ","))]]"
    }

}
