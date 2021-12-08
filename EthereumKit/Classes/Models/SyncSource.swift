public enum SyncSource {
    case webSocket(url: URL, auth: String?)
    case http(urls: [URL], blockTime: TimeInterval, auth: String?)

    public var urls: [URL] {
        switch self {
        case .webSocket(let url, _): return [url]
        case .http(let urls, _, _): return urls
        }
    }

}
