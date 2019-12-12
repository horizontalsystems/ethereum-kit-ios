public enum ApiError: Error {
    case invalidData
    case infuraError(code: Int, message: String)
}
