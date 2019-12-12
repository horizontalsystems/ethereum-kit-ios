class NodeFactory: INodeFactory {
    private let dateGenerator: () -> Date

    init(dateGenerator: @escaping () -> Date = Date.init) {
        self.dateGenerator = dateGenerator
    }

    func node(id: Data, host: String, port: Int, discoveryPort: Int) -> Node {
        return Node(id: id, host: host, port: port, discoveryPort: discoveryPort)
    }

    func newNodeRecord(id: Data, host: String, port: Int, discoveryPort: Int) -> NodeRecord {
        return NodeRecord(id: id, host: host, port: port, discoveryPort: discoveryPort, used: false, eligible: true, score: 0, timestamp: Int(dateGenerator().timeIntervalSince1970))
    }

    func nodeRecord(id: Data, host: String, port: Int, discoveryPort: Int, used: Bool, eligible: Bool, score: Int) -> NodeRecord {
        return NodeRecord(id: id, host: host, port: port, discoveryPort: discoveryPort, used: used, eligible: eligible, score: score, timestamp: Int(dateGenerator().timeIntervalSince1970))
    }

}
