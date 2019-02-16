import Foundation

class Peer {

    enum PeerError: Error {
        case peerBestBlockIsLessThanOne
        case peerHasExpiredBlockChain(localHeight: BInt, peerHeight: BInt)
        case wrongNetwork
    }

    weak var delegate: IPeerDelegate?

    private let network: INetwork
    private let bestBlock: BlockHeader
    private let devP2PPeer: DevP2PPeer
    private let protocolVersion: UInt8 = 2

    var statusSent: Bool = false
    var statusReceived: Bool = false


    init(network: INetwork, bestBlock: BlockHeader, key: ECKey, node: Node) {
        self.network = network
        self.bestBlock = bestBlock

        devP2PPeer = DevP2PPeer(key: key, node: node)
        devP2PPeer.delegate = self
    }

    func proceedHandshake() {
        if statusSent {
            if statusReceived {
                delegate?.connected()
                return
            }
        } else {
            let statusMessage = StatusMessage(
                    protocolVersion: protocolVersion,
                    networkId: network.id,
                    genesisHash: network.genesisBlockHash,
                    bestBlockTotalDifficulty: bestBlock.totalDifficulty,
                    bestBlockHash: bestBlock.hashHex,
                    bestBlockHeight: bestBlock.height
            )

            devP2PPeer.send(message: statusMessage)
            statusSent = true
        }
    }

    private func validatePeer(message: StatusMessage) throws {
        guard message.bestBlockHeight > 0 else {
            throw PeerError.peerBestBlockIsLessThanOne
        }

        guard message.bestBlockHeight >= bestBlock.height else {
            throw PeerError.peerHasExpiredBlockChain(localHeight: bestBlock.height, peerHeight: message.bestBlockHeight)
        }

        guard message.networkId == network.id && message.genesisHash == network.genesisBlockHash else {
            throw PeerError.wrongNetwork
        }
    }

    private func handle(message: IMessage) throws {
        switch message {
        case let statusMessage as StatusMessage: handle(message: statusMessage)
        case let blockHeadersMessage as BlockHeadersMessage: handle(message: blockHeadersMessage)
        default: break
        }
    }

    private func handle(message: StatusMessage) {
        statusReceived = true

        do {
            try validatePeer(message: message)
        } catch {
            print("ERROR: \(error)")
            disconnect(error: error)
        }

        proceedHandshake()
    }

    private func handle(message: BlockHeadersMessage) {
        delegate?.blocksReceived(blockHeaders: Array(message.headers.dropFirst()))
    }

}

extension Peer {

    func connect() {
        devP2PPeer.connect()
    }

    func disconnect(error: Error? = nil) {
        devP2PPeer.disconnect(error: error)
    }

    func downloadBlocksFrom(block: BlockHeader) {
        let message = GetBlockHeadersMessage(requestId: Int.random(in: 0..<Int.max), blockHash: block.hashHex)

        devP2PPeer.send(message: message)
    }

}

extension Peer: IDevP2PPeerDelegate {

    func connectionEstablished() {
        proceedHandshake()
    }

    func connectionDidDisconnect(withError error: Error?) {
//        print("Disconnected ...")
    }

    func connection(didReceiveMessage message: IMessage) {
        do {
            try self.handle(message: message)
        } catch {
            self.disconnect(error: error)
        }
    }

}
