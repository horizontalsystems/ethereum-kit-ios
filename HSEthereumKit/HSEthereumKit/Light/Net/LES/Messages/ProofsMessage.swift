import Foundation
import HSCryptoKit

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

    required init?(data: Data) {
        let rlp = RLP.decode(input: data)

        guard rlp.isList() && rlp.listValue.count > 2 else {
            return nil
        }

        requestId = rlp.listValue[0].intValue
        bv = rlp.listValue[1].intValue

        nodes = [TrieNode]()

        let rlpNodes: [RLPElement]
        if rlp.listValue[2].isList() && rlp.listValue[2].listValue.count > 0 {
            rlpNodes = rlp.listValue[2].listValue
        } else {
            rlpNodes = [RLPElement]()
        }

        for rlpNode in rlpNodes {
            nodes.append(TrieNode(rlp: rlpNode))
        }
    }

    func getValidatedState(stateRoot: Data, address: Data) throws -> AddressState {
        guard var lastNode = nodes.last else {
            throw ProofError.noNodes
        }

        guard lastNode.nodeType == TrieNode.NodeType.LEAF,
              var path = lastNode.getPath(element: nil) else {
            throw ProofError.stateNodeNotFound
        }

        let rlpState = RLP.decode(input: lastNode.elements[1])
        guard rlpState.isList() && rlpState.listValue.count == 4 else {
            throw ProofError.wrongState
        }

        let nonce = rlpState.listValue[0].intValue
        let balance = Balance(wei: rlpState.listValue[1].bIntValue)
        let storageRoot = rlpState.listValue[2].dataValue
        let codeHash = rlpState.listValue[3].dataValue

        var lastNodeKey = lastNode.hash

        for i in stride(from: nodes.count - 2, through: 0, by: -1) {
            lastNode = nodes[i]

            guard let partialPath = lastNode.getPath(element: lastNodeKey) else {
                throw ProofError.nodesNotInterconnected
            }

            path = partialPath + path
            lastNodeKey = lastNode.hash
        }

        let addressHash = CryptoKit.sha3(address)

        guard addressHash.toHexString() == path else {
            throw ProofError.pathDoesNotMatchAddressHash
        }

        guard stateRoot == lastNodeKey else {
            throw ProofError.rootHashDoesNotMatchStateRoot
        }

        return AddressState(address: address, nonce: nonce, balance: balance, storageHash: storageRoot, codeHash: codeHash)
    }

    func encoded() -> Data {
        return Data()
    }

    func toString() -> String {
        return "PROOFS [requestId: \(requestId); bv: \(bv); headers: [\(nodes.map{ $0.toString() }.joined(separator: ","))]]"
    }

}
