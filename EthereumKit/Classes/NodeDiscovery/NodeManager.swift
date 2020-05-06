import HsToolKit

class NodeManager {
    weak var delegate: INodeManagerDelegate?

    private let storage: IDiscoveryStorage
    private let nodeDiscovery: INodeDiscovery
    private let nodeFactory: INodeFactory
    private let state: NodeManagerState
    private let logger: Logger?

    init(storage: IDiscoveryStorage, nodeDiscovery: INodeDiscovery, nodeFactory: INodeFactory, state: NodeManagerState = NodeManagerState(), logger: Logger? = nil) {
        self.storage = storage
        self.nodeDiscovery = nodeDiscovery
        self.nodeFactory = nodeFactory
        self.state = state
        self.logger = logger
    }

}

extension NodeManager: INodeManager {

    var node: Node? {
        guard let node = storage.leastScoreNode(excludingIds: state.usedIds) else {
            if !nodeDiscovery.processing {
                try? nodeDiscovery.lookup()
            }
            return nil
        }

        state.add(usedId: node.id)

        return nodeFactory.node(id: node.id, host: node.host, port: node.port, discoveryPort: node.discoveryPort)
    }

    var hasFreshIds: Bool {
        return storage.leastScoreNode(excludingIds: state.usedIds) != nil
    }

    func markSuccess(id: Data) {
        state.remove(usedId: id)
        storage.increasePeerAddressScore(id: id)
    }


    func markFailed(id: Data) {
        state.remove(usedId: id)
        storage.markNodeNonEligible(id: id)
    }

    func add(nodes: [Node]) {
        guard !nodes.isEmpty else {
            return
        }

        let nodeRecords = nodes.map { nodeFactory.newNodeRecord(id: $0.id, host: $0.host, port: $0.port, discoveryPort: $0.discoveryPort) }
        logger?.debug("Adding new nodes: \(nodes.count)")

        storage.save(nodes: nodeRecords)
        delegate?.newIdsAdded()
    }

}
