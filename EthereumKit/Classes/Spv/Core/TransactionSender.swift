import RxSwift

protocol ITransactionSenderDelegate: AnyObject {
    func onSendSuccess(sendId: Int, transaction: Transaction)
    func onSendFailure(sendId: Int, error: Error)
}

class TransactionSender {
    weak var delegate: ITransactionSenderDelegate?

    private let storage: ISpvStorage
    private let transactionBuilder: TransactionBuilder

    init(storage: ISpvStorage, transactionBuilder: TransactionBuilder) {
        self.storage = storage
        self.transactionBuilder = transactionBuilder
    }

    func send(sendId: Int, taskPerformer: ITaskPerformer, rawTransaction: RawTransaction, signature: Signature) {
        taskPerformer.add(task: SendTransactionTask(sendId: sendId, rawTransaction: rawTransaction, signature: signature))
    }

}

extension TransactionSender: ISendTransactionTaskHandlerDelegate {

    func onSendSuccess(task: SendTransactionTask) {
        let transaction = transactionBuilder.transaction(rawTransaction: task.rawTransaction, signature: task.signature)

        delegate?.onSendSuccess(sendId: task.sendId, transaction: transaction)
    }

    func onSendFailure(task: SendTransactionTask, error: Error) {
        delegate?.onSendFailure(sendId: task.sendId, error: error)
    }

}
