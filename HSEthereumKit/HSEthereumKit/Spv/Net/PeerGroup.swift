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
                id: Data(hex: "e679038c2e4f9f764acd788c3935cf526f7f630b55254a122452e63e2cfae3066ca6b6c44082c2dfbe9ddffc9df80546d40ef38a0e3dfc9c8720c732446ca8f3"),
                host: "192.168.4.39",
                port: 30303,
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

}
