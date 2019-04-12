class TokenStates {

    weak var delegate: ITokenStatesDelegate?

    var states = [Data: Erc20Kit.SyncState]()

}

extension TokenStates: ITokenStates {

    func state(of contractAddress: Data) -> Erc20Kit.SyncState {
        return states[contractAddress] ?? Erc20Kit.SyncState.notSynced
    }

    func set(state: Erc20Kit.SyncState, to contractAddress: Data) {
        if self.state(of: contractAddress) != .synced {
            states[contractAddress] = state
            delegate?.onSyncStateUpdated(contractAddress: contractAddress)
        }
    }

    func clear() {
        states.removeAll()
    }

}
