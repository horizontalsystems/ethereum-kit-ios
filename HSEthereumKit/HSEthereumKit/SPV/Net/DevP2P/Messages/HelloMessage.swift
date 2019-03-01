import Foundation

class HelloMessage: IMessage {

    let p2pVersion: Int
    let clientId: String
    let capabilities: [Capability]
    let port: Int
    let peerId: Data

    init(peerId: Data, port: UInt32, capabilities: [Capability]) {
        self.p2pVersion = 4
        self.clientId = "EthereumKit"
        self.capabilities = capabilities
        self.port = Int(port)
        self.peerId = peerId
    }

    required init?(data: Data) {
        let rlp = RLP.decode(input: data)

        guard rlp.isList() && rlp.listValue.count > 4 else {
            return nil
        }

        p2pVersion = rlp.listValue[0].intValue
        clientId = rlp.listValue[1].stringValue
        capabilities = rlp.listValue[2].listValue.map{ Capability(name: $0.listValue[0].stringValue, version: $0.listValue[1].intValue) }
        port = rlp.listValue[3].intValue
        peerId = rlp.listValue[4].dataValue
    }

    func encoded() -> Data {
        let toEncode: [Any] = [
            p2pVersion,
            clientId,
            capabilities.map{ $0.toArray() },
            port,
            peerId
        ]

        return RLP.encode(toEncode)
    }

    func toString() -> String {
        return "HELLO [version: \(p2pVersion); clientId: \(clientId); capabilities: \(capabilities.map { $0.toString() }.joined(separator: ", ")); peerId: \(peerId.toHexString()); port: \(port)]"
    }

}
