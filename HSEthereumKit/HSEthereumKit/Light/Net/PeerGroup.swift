import Foundation

class PeerGroup {

    private var blockHeaders = [BlockHeader]()
    private var syncPeer: IPeer?
    private var address: Data
    weak var delegate: IPeerGroupDelegate?

    init(network: INetwork, address: String) {
        self.address = Data(hex: String(address[address.index(address.startIndex, offsetBy: 2)...]))
//        self.address = Data(hex: "f757461bdc25ee2b047d545a50768e52d530b750")
//        self.address = Data(hex: "f757461bdc25ee2b047d545a50768e52d530b751")
//        self.address = Data(hex: "37531e574427BDE92d9B3a3c2291D9A004827435")
//        self.address = Data(hex: "1b763c4b9632d6876D83B2270fF4d01b792DE479")
//        self.address = Data(hex: "401CB37eFa5d82dC51FB599e6A4B1D2b3aaeb2B2")

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

        syncPeer = LESPeer(network: network, bestBlock: network.checkpointBlock, key: myKey, node: node)
        syncPeer?.delegate = self
        blockHeaders.append(network.checkpointBlock)
    }

    func syncBlocks() {
        if let lastBlock = blockHeaders.last, let syncPeer = syncPeer {
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

            if let lastBlock = self.blockHeaders.last, let syncPeer = syncPeer {
                syncPeer.getBalance(forAddress: address, inBlockWithHash: lastBlock.hashHex)
            }

            return
        }

        self.blockHeaders += blockHeaders
        self.syncBlocks()
    }

    func proofReceived(message: ProofsMessage) {
        if let lastBlock = self.blockHeaders.last {
            do {
                let state = try message.getValidatedState(stateRoot: lastBlock.stateRoot, address: address)
                delegate?.onUpdate(state: state)
            } catch {
                print("proof result: \(error)")
            }
        }
    }

}
