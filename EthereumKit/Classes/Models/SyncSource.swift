public enum SyncSource {
    case webSocket(url: URL, auth: String?)
    case http(url: URL, blockTime: TimeInterval, auth: String?)

    public var url: URL {
        switch self {
        case .webSocket(let url, _): return url
        case .http(let url, _, _): return url
        }
    }

}
