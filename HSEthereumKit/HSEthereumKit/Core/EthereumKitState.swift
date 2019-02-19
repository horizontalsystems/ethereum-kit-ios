import Foundation

class EthereumKitState {

    var balance: Decimal?
    var lastBlockHeight: Int?
    var syncState: EthereumKit.SyncState?

    private var erc20Holders: [String: Erc20Holder] = [:]

    var isSyncing: Bool {
        if syncState == .syncing {
            return true
        }
        for holder in erc20Holders.values {
            if holder.syncState == .syncing {
                return true
            }
        }
        return false
    }

    var erc20Delegates: [IEthereumKitDelegate] {
        return erc20Holders.values.map { $0.delegate }
    }

    func has(contractAddress: String) -> Bool {
        return erc20Holders[contractAddress] != nil
    }

    func add(contractAddress: String, decimal: Int, delegate: IEthereumKitDelegate) {
        erc20Holders[contractAddress] = Erc20Holder(contractAddress: contractAddress, decimal: decimal, delegate: delegate)
    }

    func remove(contractAddress: String) {
        erc20Holders.removeValue(forKey: contractAddress)
    }

    func balance(contractAddress: String) -> Decimal? {
        return erc20Holders[contractAddress]?.balance
    }

    func syncState(contractAddress: String) -> EthereumKit.SyncState? {
        return erc20Holders[contractAddress]?.syncState
    }

    func set(balance: Decimal, contractAddress: String) {
        erc20Holders[contractAddress]?.balance = balance
    }

    func set(syncState: EthereumKit.SyncState, contractAddress: String) {
        erc20Holders[contractAddress]?.syncState = syncState
    }

    func delegate(contractAddress: String) -> IEthereumKitDelegate? {
        return erc20Holders[contractAddress]?.delegate
    }

    func clear() {
        balance = nil
        lastBlockHeight = nil
        syncState = .notSynced
        erc20Holders = [:]
    }

}
