class ProofsMessage: IInMessage {
    let requestId: Int
    let bv: Int
    var nodes: [TrieNode]

    init(requestId: Int, bv: Int, nodes: [TrieNode]) {
        self.requestId = requestId
        self.bv = bv
        self.nodes = nodes
    }

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

    func encoded() -> Data {
        return Data()
    }

    func toString() -> String {
        return "PROOFS [requestId: \(requestId); bv: \(bv.flowControlLog); nodesCount: \(nodes.count)]"
    }

}
