public enum SyncState {
    case synced
    case syncing(progress: Double?)
    case notSynced(error: Error)

    public var notSynced: Bool {
        if case .notSynced = self { return true } else { return false }
    }

    public var syncing: Bool {
        if case .syncing = self { return true } else { return false }
    }

    public var synced: Bool {
        self == .synced
    }
}

extension SyncState: Equatable {

    public static func ==(lhs: SyncState, rhs: SyncState) -> Bool {
        switch (lhs, rhs) {
        case (.synced, .synced): return true
        case (.syncing(let lhsProgress), .syncing(let rhsProgress)): return lhsProgress == rhsProgress
        case (.notSynced(let lhsError), .notSynced(let rhsError)): return "\(lhsError)" == "\(rhsError)"
        default: return false
        }
    }

}

extension SyncState: CustomStringConvertible {

    public var description: String {
        switch self {
        case .synced: return "synced"
        case .syncing(let progress): return "syncing \(progress ?? 0)"
        case .notSynced(let error): return "not synced: \(error)"
        }
    }

}
