class DisconnectMessage: IInMessage {

    enum ReasonCode: Int {
        case requested = 0x00
        case tcp_error = 0x01
        case bad_protocol = 0x02
        case useless_peer = 0x03
        case too_many_peers = 0x04
        case duplicate_peer = 0x05
        case incompatible_protocol = 0x06
        case null_identity = 0x07
        case peer_quiting = 0x08
        case unexpected_identity = 0x09
        case local_identity = 0x0A
        case ping_timeout = 0x0B
        case user_reason = 0x10
        case unknown = 0xFF
    }

    private let reason: ReasonCode

    init(reason: ReasonCode) {
        self.reason = reason
    }

    required init(data: Data) throws {
        let rlpList = try RLP.decode(input: data).listValue()

        guard rlpList.count > 0 else {
            throw MessageDecodeError.notEnoughFields
        }

        if let reason = ReasonCode(rawValue: try rlpList[0].intValue()) {
            self.reason = reason
        } else {
            self.reason = ReasonCode.unknown
        }
    }

    func encoded() -> Data {
        return RLP.encode([reason.rawValue])
    }

    func toString() -> String {
        return "DISCONNECT [reason: \(reason)]"
    }

}
