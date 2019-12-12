protocol IAccountStateSyncerDelegate: AnyObject {
    func onUpdate(accountState: AccountState)
}

class AccountStateSyncer {
    weak var delegate: IAccountStateSyncerDelegate?

    private let storage: ISpvStorage
    private let address: Data

    init(storage: ISpvStorage, address: Data) {
        self.storage = storage
        self.address = address
    }

    func sync(taskPerformer: ITaskPerformer, blockHeader: BlockHeader) {
        taskPerformer.add(task: AccountStateTask(address: address, blockHeader: blockHeader))
    }

}

extension AccountStateSyncer: IAccountStateTaskHandlerDelegate {

    func didReceive(accountState: AccountState, address: Data, blockHeader: BlockHeader) {
        storage.save(accountState: accountState)
        delegate?.onUpdate(accountState: accountState)
    }

}
