public enum SyncState {
    case synced
    case syncing
    case notSynced(error: Error)
}

extension SyncState: Equatable {

    public static func ==(lhs: SyncState, rhs: SyncState) -> Bool {
        switch (lhs, rhs) {
        case (.synced, .synced): return true
        case (.syncing, .syncing): return true
        case (.notSynced(let lhsError), .notSynced(let rhsError)): return "\(lhsError)" == "\(rhsError)"
        default: return false
        }
    }

}
