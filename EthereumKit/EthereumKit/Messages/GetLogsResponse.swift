public class GetLogsResponse: IResponse {
    public let id: Int
    public let logs: [EthereumLog]

    init(id: Int, logs: [EthereumLog]) {
        self.id = id
        self.logs = logs
    }

}
