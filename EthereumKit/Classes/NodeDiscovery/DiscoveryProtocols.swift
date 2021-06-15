import Socket

protocol INodeManager: AnyObject {
    var delegate: INodeManagerDelegate? { get set }
    var node: Node? { get }
    var hasFreshIds: Bool { get }
    func markSuccess(id: Data)
    func markFailed(id: Data)
    func add(nodes: [Node])
}

protocol INodeDiscovery {
    func lookup() throws
    var processing: Bool { get }
}

protocol INodeManagerDelegate: AnyObject {
    func newIdsAdded()
}

protocol INodeParser {
    func parse(uri: String) throws -> Node
}

protocol IDiscoveryStorage {
    func leastScoreNode(excludingIds: [Data]) -> NodeRecord?
    func increasePeerAddressScore(id: Data)
    func markNodeNonEligible(id: Data)
    func save(nodes: [NodeRecord])
    func remove(node: Node)

    func nonUsedNode() -> NodeRecord?
    func contain(nodeId: Data) -> Bool
    func setNonEligible(node: NodeRecord)
    func setUsed(node: NodeRecord)
}

protocol IUdpSocket {
    func setReadTimeout(value: UInt) throws

    func readDatagram() throws -> (bytesRead: Int, data: Data)
    @discardableResult func write(from data: Data, to address: Socket.Address) throws -> Int

    func createAddress(host: String, port: Int32) -> Socket.Address?
}

protocol INodeFactory {
    func node(id: Data, host: String, port: Int, discoveryPort: Int) -> Node
    func newNodeRecord(id: Data, host: String, port: Int, discoveryPort: Int) -> NodeRecord
    func nodeRecord(id: Data, host: String, port: Int, discoveryPort: Int, used: Bool, eligible: Bool, score: Int) -> NodeRecord
}

protocol IUdpFactory {
    func client(node: Node, timeoutInterval: TimeInterval) throws -> IUdpClient

    func pingData(from: Node, to: Node, expiration: TimeInterval) throws -> Data
    func pongData(to: Node, hash: Data, expiration: TimeInterval) throws -> Data
    func findNodeData(target: Data, expiration: TimeInterval) throws -> Data
}

protocol IUdpClient: AnyObject {
    var node: Node { get }
    var noResponse: Bool { get }
    var id: Data { get }

    var delegate: IUdpClientDelegate? { get set }

    func listen()
    func send(_ data: Data) throws
}

protocol IUdpClientDelegate: AnyObject {
    func didStop(_ client: IUdpClient, by error: Error)
    func didReceive(_ client: IUdpClient, data: Data) throws
}

protocol IPackage {
    var type: UInt8 { get }
    var expiration: Int32 { get }
}

protocol IPackageParser {
    func parse(data: Data) throws -> IPackage
}

protocol IPacketParser {
    func parse(data: Data) throws -> Packet
}

// todo: Merge?
protocol IPacketSerializer {
    func serialize(package: IPackage) throws -> Data
}

protocol IPackageSerializer {
    func serialize(package: IPackage) throws -> Data
}