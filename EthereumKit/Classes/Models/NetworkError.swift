public enum NetworkError: Error {
    case invalidUrl
    case mappingError
    case noConnection
    case serverError(status: Int, data: Any?)
}
