class PeerGroup {
    weak var delegate: IPeerGroupDelegate?

    private var syncPeer: IPeer?
    private var address: Data
    private var connectionKey: ECKey
    private var storage: ISpvStorage

    private let logger: Logger?

    init(network: INetwork, storage: ISpvStorage, connectionKey: ECKey, address: Data, logger: Logger? = nil) {
        self.address = address
        self.connectionKey = connectionKey
        self.storage = storage
        self.logger = logger

        let node = Node(
                id: Data(hex: "e679038c2e4f9f764acd788c3935cf526f7f630b55254a122452e63e2cfae3066ca6b6c44082c2dfbe9ddffc9df80546d40ef38a0e3dfc9c8720c732446ca8f3"),
                host: "192.168.4.39",
                port: 30303,
                discoveryPort: 30301
        )

        let lastBlockHeader: BlockHeader

        if let storedLastBlockHeader = storage.lastBlockHeader() {
            lastBlockHeader = storedLastBlockHeader
        } else {
            storage.save(blockHeaders: [network.checkpointBlock])
            lastBlockHeader = network.checkpointBlock
        }

        syncPeer = LESPeer.instance(network: network, lastBlockHeader: lastBlockHeader, key: connectionKey, node: node, logger: logger)
        syncPeer?.delegate = self
    }

    func syncBlocks() {
        if let lastBlockHeader = storage.lastBlockHeader() {
            syncPeer?.requestBlockHeaders(fromBlockHash: lastBlockHeader.hashHex)
        }
    }

}

extension PeerGroup: IPeerGroup {

    func start() {
        syncPeer?.connect()
    }

}

extension PeerGroup: IPeerDelegate {

    func didConnect() {
        syncBlocks()
    }

    func didReceive(blockHeaders: [BlockHeader]) {
        if blockHeaders.count <= 1 {
            print("BLOCKS SYNCED")

            if let lastBlock = storage.lastBlockHeader() {
                syncPeer?.requestProofs(forAddress: address, inBlockWithHash: lastBlock.hashHex)
            }

            return
        }

        storage.save(blockHeaders: blockHeaders)

        syncBlocks()
    }

    func didReceive(proofMessage: ProofsMessage) {
        if let lastBlock = storage.lastBlockHeader() {
            do {
                let state = try proofMessage.getValidatedState(stateRoot: lastBlock.stateRoot, address: address)
                delegate?.onUpdate(state: state)
            } catch {
                print("proof result: \(error)")
            }
        }
    }

}
