public enum SendError: Error {
    case invalidAddress
    case invalidContractAddress
    case invalidValue
    case infuraError(message: String)
}
