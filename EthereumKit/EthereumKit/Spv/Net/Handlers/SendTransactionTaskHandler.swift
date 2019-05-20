protocol ISendTransactionTaskHandlerDelegate: AnyObject {
    func onSendSuccess(task: SendTransactionTask)
    func onSendFailure(task: SendTransactionTask, error: Error)
}

class SendTransactionTaskHandler {
    weak var delegate: ISendTransactionTaskHandlerDelegate?

    private var tasks = [Int: SendTransactionTask]()

    init(delegate: ISendTransactionTaskHandlerDelegate?) {
        self.delegate = delegate
    }

}

extension SendTransactionTaskHandler: ITaskHandler {

    func perform(task: ITask, requester: ITaskHandlerRequester) -> Bool {
        guard let task = task as? SendTransactionTask else {
            return false
        }

        let requestId = RandomHelper.shared.randomInt

        tasks[requestId] = task

        let message = SendTransactionMessage(requestId: requestId, rawTransaction: task.rawTransaction, nonce: task.nonce, signature: task.signature)

        requester.send(message: message)

        return true
    }

}

extension SendTransactionTaskHandler: IMessageHandler {

    func handle(peer: IPeer, message: IInMessage) throws -> Bool {
        guard let message = message as? TransactionStatusMessage else {
            return false
        }

        guard let task = tasks.removeValue(forKey: message.requestId) else {
            return false
        }

        guard let status = message.statuses.first else {
            delegate?.onSendFailure(task: task, error: SendError.noStatus)
            return true
        }

        switch status {
        case .unknown:
            delegate?.onSendFailure(task: task, error: SendError.unknownError)
        case .error(let message):
            delegate?.onSendFailure(task: task, error: SendError.error(message: message))
        default:
            delegate?.onSendSuccess(task: task)
        }

        return true
    }

}

extension SendTransactionTaskHandler {

    enum SendError: Error {
        case noStatus
        case unknownError
        case error(message: String)
    }

}
