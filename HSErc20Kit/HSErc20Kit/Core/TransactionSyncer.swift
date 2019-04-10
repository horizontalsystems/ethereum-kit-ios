import HSEthereumKit

class TransactionSyncer {

    weak var delegate: ITransactionSyncerDelegate?

    let storage: GrdbStorage
    let addressTopic: Data

    var lastTransactionsSyncBlockHeight: Int
    var syncState: EthereumKit.SyncState

    init(storage: GrdbStorage, addressTopic: Data) {
        self.storage = storage
        self.addressTopic = addressTopic
        self.lastTransactionsSyncBlockHeight = storage.lastTransactionBlockHeight() ?? 0
        self.syncState = .notSynced
    }

    func sync(forBlock blockNumber: Int) {
        guard syncState != .syncing && lastTransactionsSyncBlockHeight < blockNumber else {
            return
        }

        updateSyncState(newState: .syncing)

        let lastTransactionBlockHeight = lastTransactionsSyncBlockHeight
        lastTransactionsSyncBlockHeight = blockNumber

        let topics = [
            [Erc20Kit.transferEventTopic, addressTopic],
            [Erc20Kit.transferEventTopic, nil, addressTopic]
        ]

        let request = GetLogsRequest(topics: topics, fromBlock: lastTransactionBlockHeight + 1, toBlock: blockNumber, pullTimestamps: false)
        delegate?.send(request: request)
    }

    func handle(response: GetLogsResponse) {
        let transactions = response.logs.compactMap {
            Transaction(log: $0)
        }
        storage.save(transactions: transactions)
        updateSyncState(newState: .synced)
    }

    private func updateSyncState(newState: EthereumKit.SyncState) {
        guard newState != syncState else {
            return
        }

        syncState = newState
        delegate?.onSyncStateUpdated(state: syncState)
    }

}
