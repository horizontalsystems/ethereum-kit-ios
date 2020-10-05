import RxSwift

protocol ITransactionSenderDelegate: AnyObject {
    func onSendSuccess(sendId: Int, transaction: Transaction)
    func onSendFailure(sendId: Int, error: Error)
}

class TransactionSender {
    weak var delegate: ITransactionSenderDelegate?

    private let storage: ISpvStorage
    private let transactionBuilder: TransactionBuilder
    private let transactionSigner: TransactionSigner

    init(storage: ISpvStorage, transactionBuilder: TransactionBuilder, transactionSigner: TransactionSigner) {
        self.storage = storage
        self.transactionBuilder = transactionBuilder
        self.transactionSigner = transactionSigner
    }

    func send(sendId: Int, taskPerformer: ITaskPerformer, rawTransaction: RawTransaction) throws {
        let signature = try transactionSigner.signature(rawTransaction: rawTransaction)

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
