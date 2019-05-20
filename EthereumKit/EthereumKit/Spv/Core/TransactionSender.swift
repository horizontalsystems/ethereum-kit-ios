import RxSwift

protocol ITransactionSenderDelegate: AnyObject {
    func onSendSuccess(sendId: Int, transaction: Transaction)
    func onSendFailure(sendId: Int, error: Error)
}

class TransactionSender {
    weak var delegate: ITransactionSenderDelegate?

    private let address: Data
    private let storage: ISpvStorage
    private let transactionBuilder: TransactionBuilder
    private let transactionSigner: TransactionSigner

    init(address: Data, storage: ISpvStorage, transactionBuilder: TransactionBuilder, transactionSigner: TransactionSigner) {
        self.address = address
        self.storage = storage
        self.transactionBuilder = transactionBuilder
        self.transactionSigner = transactionSigner
    }

    func send(sendId: Int, taskPerformer: ITaskPerformer, rawTransaction: RawTransaction) throws {
        guard let accountState = storage.accountState else {
            throw SendError.noAccountState
        }

        let signature = try transactionSigner.sign(rawTransaction: rawTransaction, nonce: accountState.nonce)

        taskPerformer.add(task: SendTransactionTask(sendId: sendId, rawTransaction: rawTransaction, nonce: accountState.nonce, signature: signature))
    }

}

extension TransactionSender: ISendTransactionTaskHandlerDelegate {

    func onSendSuccess(task: SendTransactionTask) {
        let transaction = transactionBuilder.transaction(rawTransaction: task.rawTransaction, nonce: task.nonce, signature: task.signature, address: address)

        storage.save(transactions: [transaction])

        delegate?.onSendSuccess(sendId: task.sendId, transaction: transaction)
    }

    func onSendFailure(task: SendTransactionTask, error: Error) {
        delegate?.onSendFailure(sendId: task.sendId, error: error)
    }

}

extension TransactionSender {

    enum SendError: Error {
        case noAccountState
    }

}
