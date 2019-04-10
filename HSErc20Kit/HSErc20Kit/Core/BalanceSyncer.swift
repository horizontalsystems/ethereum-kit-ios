import HSEthereumKit

class BalanceSyncer {

    weak var delegate: IBalanceSyncerDelegate?

    let storage: GrdbStorage

    var tokenStates = [Data: EthereumKit.SyncState]()

    init(storage: GrdbStorage) {
        self.storage = storage
    }

    func sync(forBlock blockNumber: Int) {
        guard let delegate = self.delegate else {
            return
        }

        for (contractAddress, token) in delegate.tokens {
            if let syncState = tokenStates[contractAddress], syncState == .syncing {
                continue
            }

            if let lastSyncBlockHeight = token.syncedBlockHeight, lastSyncBlockHeight >= blockNumber {
                continue
            }

            updateSyncState(contractAddress: contractAddress, newState: .syncing)
            let request = GetStorageAtRequest(contractAddress: contractAddress, position: token.contractBalanceKey, blockNumber: blockNumber)
            delegate.send(request: request)
        }
    }

    func handle(response: GetStorageAtResponse) {
        guard let delegate = self.delegate else {
            return
        }

        guard let newValue = BInt(response.balanceValue.toHexString(), radix: 16) else {
            return
        }

        guard let token = delegate.tokens[response.contractAddress] else {
            return
        }

        if let lastSyncBlockHeight = token.syncedBlockHeight, lastSyncBlockHeight > response.blockNumber {
            return
        }

        token.balance = newValue
        token.syncedBlockHeight = response.blockNumber
        storage.save(token: token)
        updateSyncState(contractAddress: token.contractAddress, newState: .synced)
        delegate.onBalanceUpdated(contractAddress: token.contractAddress)
    }

    private func updateSyncState(contractAddress: Data, newState: EthereumKit.SyncState) {
        guard newState != tokenStates[contractAddress] else {
            return
        }

        tokenStates[contractAddress] = newState
        delegate?.onSyncStateUpdated(contractAddress: contractAddress, state: newState)
    }

}
