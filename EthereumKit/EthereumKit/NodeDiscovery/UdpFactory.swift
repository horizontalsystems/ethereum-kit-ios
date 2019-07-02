class UdpFactory: IUdpFactory {
    private let packetSerializer: IPacketSerializer
    private let dateGenerator: () -> Date

    init(packetSerializer: IPacketSerializer, dateGenerator: @escaping () -> Date = Date.init) {
        self.packetSerializer = packetSerializer
        self.dateGenerator = dateGenerator
    }

    func client(node: Node, timeoutInterval: TimeInterval) throws -> IUdpClient {
        return try UdpClient(node: node, timeoutInterval: timeoutInterval)
    }

    func pingData(from: Node, to: Node, expiration: TimeInterval) throws -> Data {
        let pingPackage = PingPackage(from: from, to: to, expiration: Int32(dateGenerator().timeIntervalSince1970 + expiration))
        return try packetSerializer.serialize(package: pingPackage)

    }

    func pongData(to: Node, hash: Data, expiration: TimeInterval) throws -> Data {
        let pongPackage = PongPackage(to: to, pingHash: hash, expiration: Int32(dateGenerator().timeIntervalSince1970 + expiration))
        return try packetSerializer.serialize(package: pongPackage)
    }

    func findNodeData(target: Data, expiration: TimeInterval) throws -> Data {
        let findNodePackage = FindNodePackage(target: target, expiration: Int32(dateGenerator().timeIntervalSince1970 + expiration))
        return try packetSerializer.serialize(package: findNodePackage)
    }
}
