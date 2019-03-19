class PeerGroup {
    private let headersLimit = 50

    weak var delegate: IPeerGroupDelegate?

    private let network: INetwork
    private let storage: ISpvStorage
    private let connectionKey: ECKey
    private let address: Data
    private let logger: Logger?

    private var syncPeer: ILESPeer?
    private var syncing = false

    init(network: INetwork, storage: ISpvStorage, connectionKey: ECKey, address: Data, logger: Logger? = nil) {
        self.network = network
        self.storage = storage
        self.connectionKey = connectionKey
        self.address = address
        self.logger = logger

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

//        let node = Node(
//                id: Data(hex: "2d86877fbb2fcc3c27a4fa14fa8c5041ba711ce9682c38a95786c4c948f8e0420c7676316a18fc742154aa1df79cfaf6c59536bd61a9e63c6cc4b0e0b7ef7ec4"),
//                host: "13.83.92.81",
//                port: 30303,
//                discoveryPort: 30301
//        )

        let lastBlockHeader: BlockHeader

        if let storedLastBlockHeader = storage.lastBlockHeader {
            lastBlockHeader = storedLastBlockHeader
        } else {
            storage.save(blockHeaders: [network.checkpointBlock])
            lastBlockHeader = network.checkpointBlock
        }

        syncPeer = LESPeer.instance(network: network, lastBlockHeader: lastBlockHeader, key: connectionKey, node: node, logger: logger)
        syncPeer?.delegate = self
    }

    func syncBlocks() {
        if let lastBlockHeader = storage.lastBlockHeader {
            syncPeer?.requestBlockHeaders(blockHash: lastBlockHeader.hashHex, limit: headersLimit)
        }
    }

    private var lastBlockHeader: BlockHeader {
        return storage.lastBlockHeader ?? network.checkpointBlock
    }

}

extension PeerGroup: IPeerGroup {

    func start() {
        syncPeer?.connect()
    }

}

extension PeerGroup: ILESPeerDelegate {

    func didConnect() {
        syncing = true
        syncBlocks()
    }

    func didReceive(blockHeaders: [BlockHeader], blockHash: Data) {
        storage.save(blockHeaders: blockHeaders)

        if blockHeaders.count < headersLimit {
            print("BLOCKS SYNCED")

            syncing = false

            if let lastBlockHeader = storage.lastBlockHeader {
                syncPeer?.requestAccountState(address: address, blockHeader: lastBlockHeader)
            }

            return
        }

        syncBlocks()
    }

    func didReceive(accountState: AccountState, address: Data, blockHeader: BlockHeader) {
        delegate?.onUpdate(state: accountState)
    }

    func didAnnounce(blockHash: Data, blockHeight: BInt) {
        guard !syncing else {
            return
        }

        syncing = true
        syncBlocks()
    }

}
