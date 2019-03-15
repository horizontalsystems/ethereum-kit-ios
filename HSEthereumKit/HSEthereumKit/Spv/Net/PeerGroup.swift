class PeerGroup {
    weak var delegate: IPeerGroupDelegate?

    private let network: INetwork
    private let storage: ISpvStorage
    private let connectionKey: ECKey
    private let address: Data
    private let logger: Logger?

    private var syncPeer: ILESPeer?

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
            syncPeer?.requestBlockHeaders(blockHash: lastBlockHeader.hashHex)
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
        syncBlocks()
    }

    func didReceive(blockHeaders: [BlockHeader], blockHash: Data) {
        if blockHeaders.count <= 1 {
            print("BLOCKS SYNCED")

            if let lastBlockHeader = storage.lastBlockHeader {
                syncPeer?.requestAccountState(address: address, blockHeader: lastBlockHeader)
            }

            return
        }

        storage.save(blockHeaders: blockHeaders)

        syncBlocks()
    }

    func didReceive(accountState: AccountState, address: Data, blockHeader: BlockHeader) {
        delegate?.onUpdate(state: accountState)
    }

    func didAnnounce(blockHash: Data, blockHeight: BInt) {
    }

}
