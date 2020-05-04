class PeerGroupState {
    var syncPeer: IPeer?
    var syncState: SyncState = .notSynced(error: SpvBlockchain.SyncError.stubError)
}
