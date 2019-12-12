import Foundation
import Socket

enum DiscoveryError: Error {
    case allNodesUsed
}

class NodeDiscovery {
    static let alpha = 3
    static let timeoutInterval: TimeInterval = 10_000
    static let expirationInterval: TimeInterval = 20
    static let selfHost = "127.0.0.1"
    static let selfPort = 30303

    private let factory: IUdpFactory
    private let state: NodeDiscoveryState

    private let discoveryStorage: IDiscoveryStorage
    weak var nodeManager: INodeManager?

    private let nodeParser: INodeParser
    private let packetParser: IPacketParser

    private let selfNode: Node

    private var nodes = [Node]()

    let queue = DispatchQueue.global(qos: .userInteractive)


    init(ecKey: ECKey, factory: IUdpFactory, discoveryStorage: IDiscoveryStorage, state: NodeDiscoveryState = NodeDiscoveryState(), nodeParser: INodeParser, packetParser: IPacketParser) {
        let selfNodeId = ecKey.publicKeyPoint.x + ecKey.publicKeyPoint.y
        selfNode = Node(id: selfNodeId, host: NodeDiscovery.selfHost, port: NodeDiscovery.selfPort, discoveryPort: NodeDiscovery.selfPort)

        self.factory = factory
        self.discoveryStorage = discoveryStorage
        self.state = state

        self.nodeParser = nodeParser
        self.packetParser = packetParser
    }

    private func findNeighbors(from node: Node) throws {
        // create and add client to state
        let client = try factory.client(node: node, timeoutInterval: NodeDiscovery.timeoutInterval)
        state.add(client: client)

        // listen client
        client.delegate = self
        client.listen()

        //send ping package and findNode package
        let pingData = try factory.pingData(from: selfNode, to: node, expiration: NodeDiscovery.expirationInterval)
        try client.send(pingData)

        let findNodeData = try factory.findNodeData(target: selfNode.id, expiration: NodeDiscovery.expirationInterval)
        try client.send(findNodeData)
    }

}

extension NodeDiscovery: INodeDiscovery {

    func lookup() throws {
        // if there no one not used node we can't discovery new nodes.
        var discovering = false
        for _ in 0..<NodeDiscovery.alpha {
            if let node = discoveryStorage.nonUsedNode() {
                discovering = true
                discoveryStorage.setUsed(node: node)

                try findNeighbors(from: Node(id: node.id, host: node.host, port: node.port, discoveryPort: node.discoveryPort))
            } else if !discovering {
                throw DiscoveryError.allNodesUsed
            }
        }
    }

    var processing: Bool {
        return !state.clients.isEmpty
    }

}

extension NodeDiscovery: IUdpClientDelegate {

    func didStop(_ client: IUdpClient, by error: Error) {
        if client.noResponse {
            discoveryStorage.remove(node: client.node)
        }
        state.remove(client: client)
    }

    func didReceive(_ client: IUdpClient, data: Data) throws {
        guard let packet = try? packetParser.parse(data: data) else {
            return
        }
        switch packet.type {
        case 1:
            guard let pingPackage = packet.package as? PingPackage else {
                throw PacketParseError.wrongType
            }
            // todo: merge with ping method

            let pongData = try factory.pongData(to: pingPackage.from, hash: packet.hash, expiration: NodeDiscovery.expirationInterval)
            try client.send(pongData)

            let findNodeData = try factory.findNodeData(target: selfNode.id, expiration: NodeDiscovery.expirationInterval)
            try client.send(findNodeData)
        case 4:
            guard let neighborsPackage = packet.package as? NeighborsPackage else {
                throw PacketParseError.wrongType
            }
            nodeManager?.add(nodes: neighborsPackage.nodes)
        default: ()
        }
    }

}
