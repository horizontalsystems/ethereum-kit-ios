public enum SyncSource {
    case infuraWebSocket(id: String, secret: String?)
    case infura(id: String, secret: String?)
//    case incubed
}
