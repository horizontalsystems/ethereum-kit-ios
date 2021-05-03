public enum SyncSource {
    case webSocket(url: URL, auth: String?)
    case http(url: URL, blockTime: TimeInterval, auth: String?)
}
