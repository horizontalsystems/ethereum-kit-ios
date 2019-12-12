protocol IHandshakeTaskHandlerDelegate: AnyObject {
    func didCompleteHandshake(peer: IPeer, bestBlockHash: Data, bestBlockHeight: Int)
}

class HandshakeTaskHandler {
    weak var delegate: IHandshakeTaskHandlerDelegate?

    private var tasks = [String: HandshakeTask]()

    init(delegate: IHandshakeTaskHandlerDelegate?) {
        self.delegate = delegate
    }
}

extension HandshakeTaskHandler: ITaskHandler {

    func perform(task: ITask, requester: ITaskHandlerRequester) -> Bool {
        guard let task = task as? HandshakeTask else {
            return false
        }

        tasks[task.peerId] = task

        let statusMessage = StatusMessage(
                protocolVersion: LESPeer.capability.version,
                networkId: task.networkId,
                genesisHash: task.genesisHash,
                headTotalDifficulty: task.headTotalDifficulty,
                headHash: task.headHash,
                headHeight: task.headHeight
        )

        requester.send(message: statusMessage)

        return true
    }

}

extension HandshakeTaskHandler: IMessageHandler {

    func handle(peer: IPeer, message: IInMessage) throws -> Bool {
        guard let message = message as? StatusMessage else {
            return false
        }

        guard let task = tasks.removeValue(forKey: peer.id) else {
            return false
        }

        guard message.protocolVersion == LESPeer.capability.version else {
            throw LESPeer.ValidationError.invalidProtocolVersion
        }

        guard message.networkId == task.networkId else {
            throw LESPeer.ValidationError.wrongNetwork
        }

        guard message.genesisHash == task.genesisHash else {
            throw LESPeer.ValidationError.wrongNetwork
        }

        guard message.headHeight >= task.headHeight else {
            throw LESPeer.ValidationError.expiredBestBlockHeight
        }

        delegate?.didCompleteHandshake(peer: peer, bestBlockHash: message.headHash, bestBlockHeight: message.headHeight)

        return true
    }

}
