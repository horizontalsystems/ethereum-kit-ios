import HsToolKit

class PeerProvider {
    private let network: INetwork
    private let connectionKey: ECKey
    private let logger: Logger?

    init(network: INetwork, connectionKey: ECKey, logger: Logger? = nil) {
        self.network = network
        self.connectionKey = connectionKey
        self.logger = logger
    }

}

extension PeerProvider: IPeerProvider {

    func peer() -> IPeer {
        let node: Node

        node = Node(
                id: Data(hex: "c1b4c43ae757560b403cc420910169154fa5dfa6ba4362465fda7abd4a1dbd4e6b83be07fc8123f9fa0430668fe8413690c0a54d6463a45677dd39bb53034990")!,
                host: "localhost",
                port: 30303,
                discoveryPort: 30301
        )

        return LESPeer.instance(key: connectionKey, node: node, logger: logger)
    }

}
