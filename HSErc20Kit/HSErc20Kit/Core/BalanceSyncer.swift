import HSEthereumKit

class BalanceSyncer {

    weak var delegate: IBalanceSyncerDelegate?

    let storage: GrdbStorage
    let tokenStates: TokenStates
    let dataProvider: DataProvider

    var tokensFetching = [Data: Bool]()

    init(storage: GrdbStorage, tokenStates: TokenStates, dataProvider: DataProvider) {
        self.storage = storage
        self.tokenStates = tokenStates
        self.dataProvider = dataProvider
    }

    private func onBalanceReceived(token: Token, balance: BInt, blockNumber: Int) {
        if let lastSyncBlockHeight = token.syncedBlockHeight, lastSyncBlockHeight >= blockNumber {
            return
        }

        token.balance = balance
        token.syncedBlockHeight = blockNumber
        storage.save(token: token)

        delegate?.onBalanceUpdated(contractAddress: token.contractAddress)
        tokenStates.set(state: .synced, to: token.contractAddress)

        tokensFetching[token.contractAddress] = false
    }

}

extension BalanceSyncer: IBalanceSyncer {

    func sync(forBlock blockNumber: Int, token: Token) {
        if let lastSyncBlockHeight = token.syncedBlockHeight, lastSyncBlockHeight >= blockNumber {
            return
        }

        if let fetching = tokensFetching[token.contractAddress], fetching {
            return
        }

        tokensFetching[token.contractAddress] = true
        dataProvider.getStorageAt(for: token, toBlock: blockNumber, completeFunction: onBalanceReceived)
    }

    func setSynced(forBlock blockNumber: Int, token: Token) {
        token.syncedBlockHeight = blockNumber
        storage.save(token: token)

        tokenStates.set(state: .synced, to: token.contractAddress)
    }

}
