protocol IBlockHeadersTaskHandlerDelegate: AnyObject {
    func didReceive(peer: IPeer, blockHeaders: [BlockHeader], blockHeader: BlockHeader, reverse: Bool)
}

class BlockHeadersTaskHandler {
    weak var delegate: IBlockHeadersTaskHandlerDelegate?

    private var tasks = [Int: BlockHeadersTask]()

    init(delegate: IBlockHeadersTaskHandlerDelegate?) {
        self.delegate = delegate
    }

}

extension BlockHeadersTaskHandler: ITaskHandler {

    func perform(task: ITask, requester: ITaskHandlerRequester) -> Bool {
        guard let task = task as? BlockHeadersTask else {
            return false
        }

        let requestId = RandomHelper.shared.randomInt

        tasks[requestId] = task

        let message = GetBlockHeadersMessage(requestId: requestId, blockHeight: task.blockHeader.height, maxHeaders: task.limit, reverse: task.reverse ? 1 : 0)

        requester.send(message: message)

        return true
    }

}

extension BlockHeadersTaskHandler: IMessageHandler {

    func handle(peer: IPeer, message: IInMessage) throws -> Bool {
        guard let message = message as? BlockHeadersMessage else {
            return false
        }

        guard let task = tasks.removeValue(forKey: message.requestId) else {
            return false
        }

        delegate?.didReceive(peer: peer, blockHeaders: message.headers, blockHeader: task.blockHeader, reverse: task.reverse)

        return true
    }

}
