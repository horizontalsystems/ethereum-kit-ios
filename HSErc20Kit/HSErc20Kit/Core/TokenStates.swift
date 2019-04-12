class TokenStates {

    var states = [Data: Erc20Kit.SyncState]()

}

extension TokenStates: ITokenStates {

    func state(of contractAddress: Data) -> Erc20Kit.SyncState {
        return states[contractAddress] ?? Erc20Kit.SyncState.notSynced
    }

    func set(_ state: Erc20Kit.SyncState, to: Data) {
        states[to] = state
    }

    func clear() {
        states.removeAll()
    }

}
