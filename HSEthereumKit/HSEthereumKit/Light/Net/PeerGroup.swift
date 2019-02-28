import Foundation

class PeerGroup {

    private var syncPeer: IPeer?
    private var address: Data
    private var connectionKey: ECKey
    private var storage: ILightStorage
    weak var delegate: IPeerGroupDelegate?

    init(network: INetwork, storage: ILightStorage, connectionKey: ECKey, address: Data) {
        self.address = address
        self.connectionKey = connectionKey
        self.storage = storage

        let node = Node(
                id: Data(hex: "e679038c2e4f9f764acd788c3935cf526f7f630b55254a122452e63e2cfae3066ca6b6c44082c2dfbe9ddffc9df80546d40ef38a0e3dfc9c8720c732446ca8f3"),
                host: "192.168.4.39",
                port: 30303,
                discoveryPort: 30301
        )

        syncPeer = LESPeer(network: network, bestBlock: network.checkpointBlock, key: connectionKey, node: node)
        syncPeer?.delegate = self

        if storage.lastBlockHeader() == nil {
            storage.save(blockHeaders: [network.checkpointBlock])
        }
    }

    func syncBlocks() {
        if let lastBlock = storage.lastBlockHeader(), let syncPeer = syncPeer {
            syncPeer.downloadBlocksFrom(block: lastBlock)
        }
    }

}

extension PeerGroup: IPeerGroup {

    func start() {
        syncPeer?.connect()
    }

}

extension PeerGroup: IPeerDelegate {

    func connected() {
        syncBlocks()
    }

    func blocksReceived(blockHeaders: [BlockHeader]) {
        if blockHeaders.count < 2 {
            print("blocks synced!")

            if let lastBlock = storage.lastBlockHeader(), let syncPeer = syncPeer {
                syncPeer.getBalance(forAddress: address, inBlockWithHash: lastBlock.hashHex)
            }

            return
        }

        storage.save(blockHeaders: blockHeaders)
        self.syncBlocks()
    }

    func proofReceived(message: ProofsMessage) {
        if let lastBlock = storage.lastBlockHeader() {
            do {
                let state = try message.getValidatedState(stateRoot: lastBlock.stateRoot, address: address)
                delegate?.onUpdate(state: state)
            } catch {
                print("proof result: \(error)")
            }
        }
    }

}
