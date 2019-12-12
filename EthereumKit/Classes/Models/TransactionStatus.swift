public enum TransactionStatus: CustomStringConvertible {
    case success
    case failed
    case pending
    case notFound

    public var description: String {
        switch self {
        case .success: return "Success"
        case .failed: return "Failed"
        case .pending: return "Pending"
        case .notFound: return "Not Found"
        }
    }
    
}
