protocol IAccountStateSyncerDelegate: AnyObject {
    func onUpdate(accountState: AccountStateSpv)
}

class AccountStateSyncer {
    weak var delegate: IAccountStateSyncerDelegate?

    private let storage: ISpvStorage
    private let address: Address

    init(storage: ISpvStorage, address: Address) {
        self.storage = storage
        self.address = address
    }

    func sync(taskPerformer: ITaskPerformer, blockHeader: BlockHeader) {
        taskPerformer.add(task: AccountStateTask(address: address, blockHeader: blockHeader))
    }

}

extension AccountStateSyncer: IAccountStateTaskHandlerDelegate {

    func didReceive(accountState: AccountStateSpv, address: Address, blockHeader: BlockHeader) {
        storage.save(accountState: accountState)
        delegate?.onUpdate(accountState: accountState)
    }

}
