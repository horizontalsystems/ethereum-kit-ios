class PingMessage: IInMessage {
    private static let payload = Data([UInt8(0xc0)])

    init() {
    }

    required init(data: Data) throws {
    }

    func encoded() -> Data {
        return PingMessage.payload
    }

    func toString() -> String {
        return "PING"
    }

}
