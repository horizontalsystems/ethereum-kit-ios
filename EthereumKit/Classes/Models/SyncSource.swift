public enum SyncSource {
    case webSocket(url: URL, auth: String?)
    case http(url: URL, auth: String?)
}
