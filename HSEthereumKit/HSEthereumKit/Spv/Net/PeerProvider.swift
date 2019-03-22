class PeerProvider {
    private let network: INetwork
    private let storage: ISpvStorage
    private let connectionKey: ECKey
    private let logger: Logger?

    init(network: INetwork, storage: ISpvStorage, connectionKey: ECKey, logger: Logger? = nil) {
        self.network = network
        self.storage = storage
        self.connectionKey = connectionKey
        self.logger = logger
    }

}

extension PeerProvider: IPeerProvider {

    func peer() -> IPeer {

        let node = Node(
                id: Data(hex: "f9a9a1b2f68dc119b0f44ba579cbc40da1f817ddbdb1045a57fa8159c51eb0f826786ce9e8b327d04c9ad075f2c52da90e9f84ee4dde3a2a911bb1270ef23f6d"),
                host: "eth-testnet.horizontalsystems.xyz",
                port: 20303,
                discoveryPort: 30301
        )

//        let node = Node(
//                id: Data(hex: "053d2f57829e5785d10697fa6c5333e4d98cc564dbadd87805fd4fedeb09cbcb642306e3a73bd4191b27f821fb442fcf964317d6a520b29651e7dd09d1beb0ec"),
//                host: "79.98.29.154",
//                port: 30303,
//                discoveryPort: 30301
//        )
//
//        let node = Node(
//                id: Data(hex: "2d86877fbb2fcc3c27a4fa14fa8c5041ba711ce9682c38a95786c4c948f8e0420c7676316a18fc742154aa1df79cfaf6c59536bd61a9e63c6cc4b0e0b7ef7ec4"),
//                host: "13.83.92.81",
//                port: 30303,
//                discoveryPort: 30301
//        )

        let lastBlockHeader = storage.lastBlockHeader ?? network.checkpointBlock

        return LESPeer.instance(network: network, lastBlockHeader: lastBlockHeader, key: connectionKey, node: node, logger: logger)
    }

}
