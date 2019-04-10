public class GetLogsRequest: IRequest {
    public let id: Int

    let address: Data?
    let topics: [Any]
    let fromBlock: Int?
    let toBlock: Int?
    let pullTimestamps: Bool

    public init(address: Data? = nil, topics: [Any], fromBlock: Int? = nil, toBlock: Int? = nil, pullTimestamps: Bool) {
        self.id = RandomHelper.shared.randomInt
        self.address = address
        self.topics = topics
        self.fromBlock = fromBlock
        self.toBlock = toBlock
        self.pullTimestamps = pullTimestamps
    }

}
