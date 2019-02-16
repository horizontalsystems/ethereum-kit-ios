import Foundation

class PeerGroup {

    private var blockHeaders = [BlockHeader]()
    private var syncPeer: Peer?

    init(network: INetwork) {
        let myKey = ECKey(
                privateKey: Data(hex: "80eb91774979181bcbb6704fa204fed5b8794cea9ebaf2d9e6cf8133622c05ad"),
                publicKeyPoint: ECPoint(nodeId: Data(hex: "577f676acd7c7103d535c66f83463ade981e8018b8ff733303479b8e10d57f728cae950df05be3d022ae336bc81b06f4ec58102fc1cdb6b8b02b09e7d1882277"))
        )
        let node = Node(
                id: Data(hex: "e679038c2e4f9f764acd788c3935cf526f7f630b55254a122452e63e2cfae3066ca6b6c44082c2dfbe9ddffc9df80546d40ef38a0e3dfc9c8720c732446ca8f3"),
                host: "192.168.4.39",
                port: 30303,
                discoveryPort: 30301
        )

        syncPeer = Peer(network: network, bestBlock: network.checkpointBlock, key: myKey, node: node)
        syncPeer?.delegate = self
        blockHeaders.append(network.checkpointBlock)
    }


    func start() {
        syncPeer!.connect()
    }

    func syncBlocks() {
        if let lastBlock = blockHeaders.last, let syncPeer = syncPeer {
            syncPeer.downloadBlocksFrom(block: lastBlock)
        }
    }

}

extension PeerGroup: IPeerDelegate {

    func blocksReceived(blockHeaders: [BlockHeader]) {
        if blockHeaders.count < 2 {
            print("blocks synced!")
            return
        }

        self.blockHeaders += blockHeaders
        self.syncBlocks()
    }

    func connected() {
        syncBlocks()
    }

}
