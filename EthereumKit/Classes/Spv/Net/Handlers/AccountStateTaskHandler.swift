protocol IAccountStateTaskHandlerDelegate: AnyObject {
    func didReceive(accountState: AccountStateSpv, address: Address, blockHeader: BlockHeader)
}

class AccountStateTaskHandler {
    weak var delegate: IAccountStateTaskHandlerDelegate?

    init(delegate: IAccountStateTaskHandlerDelegate?) {
        self.delegate = delegate
    }

    private var tasks = [Int: AccountStateTask]()

    private func parse(proofsMessage: ProofsMessage, task: AccountStateTask) throws -> AccountStateSpv {
        guard var lastNode = proofsMessage.nodes.last else {
            throw ProofError.noNodes
        }

        guard lastNode.nodeType == TrieNode.NodeType.LEAF, var path = lastNode.getPath(element: nil) else {
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

        let addressHash = CryptoUtils.shared.sha3(task.address.raw)

        guard addressHash.hex == path else {
            throw ProofError.pathDoesNotMatchAddressHash
        }

        guard task.blockHeader.stateRoot == lastNodeKey else {
            throw ProofError.rootHashDoesNotMatchStateRoot
        }

        return AccountStateSpv(address: task.address, nonce: nonce, balance: balance, storageHash: storageRoot, codeHash: codeHash)
    }

}

extension AccountStateTaskHandler: ITaskHandler {

    func perform(task: ITask, requester: ITaskHandlerRequester) -> Bool {
        guard let task = task as? AccountStateTask else {
            return false
        }

        let requestId = RandomHelper.shared.randomInt

        tasks[requestId] = task

        let message = GetProofsMessage(requestId: requestId, blockHash: task.blockHeader.hashHex, key: task.address.raw)

        requester.send(message: message)

        return true
    }

}

extension AccountStateTaskHandler: IMessageHandler {

    func handle(peer: IPeer, message: IInMessage) throws -> Bool {
        guard let message = message as? ProofsMessage else {
            return false
        }

        guard let task = tasks.removeValue(forKey: message.requestId) else {
            return false
        }

        let accountState = try parse(proofsMessage: message, task: task)

        delegate?.didReceive(accountState: accountState, address: task.address, blockHeader: task.blockHeader)

        return true
    }

}

extension AccountStateTaskHandler {

    enum ProofError: Error {
        case noNodes
        case stateNodeNotFound
        case nodesNotInterconnected
        case pathDoesNotMatchAddressHash
        case rootHashDoesNotMatchStateRoot
        case wrongState
    }

}
