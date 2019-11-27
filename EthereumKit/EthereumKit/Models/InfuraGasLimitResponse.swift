public struct InfuraError: Error {
    let errorMessage: String
    let errorCode: Int
}

struct InfuraGasLimitResponse {
    let value: String?
    let error: InfuraError?
}
