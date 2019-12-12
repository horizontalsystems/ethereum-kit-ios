public enum SyncMode {
    case api
    case spv(nodePrivateKey: Data)
    case geth
}
