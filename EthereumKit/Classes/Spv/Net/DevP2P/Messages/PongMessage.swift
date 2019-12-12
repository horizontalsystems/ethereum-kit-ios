class PongMessage: IInMessage, IOutMessage {
    private static let payload = Data([UInt8(0xc0)])

    init() {
    }

    required init(data: Data) throws {
    }

    func encoded() -> Data {
        return PongMessage.payload
    }

    func toString() -> String {
        return "PONG"
    }

}
