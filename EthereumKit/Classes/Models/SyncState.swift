public enum SyncState: Equatable, CustomStringConvertible {
    case synced
    case syncing(progress: Double?)
    case notSynced

    public static func ==(lhs: SyncState, rhs: SyncState) -> Bool {
        switch (lhs, rhs) {
        case (.synced, .synced), (.notSynced, .notSynced): return true
        case (.syncing(let lhsProgress), .syncing(let rhsProgress)): return lhsProgress == rhsProgress
        default: return false
        }
    }

    public var description: String {
        switch self {
        case .synced: return "synced"
        case .syncing(let progress): return "syncing \(progress ?? 0)"
        case .notSynced: return "not synced"
        }
    }

}
