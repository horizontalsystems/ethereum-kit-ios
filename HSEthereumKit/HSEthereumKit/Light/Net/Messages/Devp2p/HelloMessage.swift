import Foundation

class HelloMessage : IMessage {

    static let code = 0x00
    var code: Int { return HelloMessage.code }

    private let p2pVersion: Int
    private let clientId: String
    private let capabilities: [Capability]
    private let port: Int
    private let peerId: Data

    init(peerId: Data, port: UInt32) {
        self.p2pVersion = 4
        self.clientId = "EthereumKit"
        self.capabilities = [Capability(name: "p2p", version: 4), Capability(name: "les", version: 2)]
        self.port = Int(port)
        self.peerId = peerId
    }

    init(data: Data) {
        let rlp = try! RLP.decode(input: data)

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

        return try! RLP.encode(toEncode)
    }

    func toString() -> String {
        return "[version: \(p2pVersion); clientId: \(clientId); capabilities: \(capabilities.map { $0.toString() }.joined(separator: ", ")); peerId: \(peerId.toHexString()); port: \(port)]"
    }


    class Capability {

        let name: String
        let version: Int

        init(name: String, version: Int) {
            self.name = name
            self.version = version
        }

        func toArray() -> [Any] {
            return [name, version]
        }

        func toString() -> String {
            return "[name: \(name); version: \(version)]"
        }
    }

}
