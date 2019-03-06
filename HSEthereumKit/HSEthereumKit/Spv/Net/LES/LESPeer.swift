import Foundation

class LESPeer {

    enum LESPeerError: Error {
        case peerBestBlockIsLessThanOne
        case peerHasExpiredBlockChain(localHeight: BInt, peerHeight: BInt)
        case wrongNetwork
    }

    private let protocolVersion: UInt8 = 2
    private let capability = Capability(name: "les", version: 2, packetTypesMap: [
        0x00: StatusMessage.self,
        0x01: AnnounceMessage.self,
        0x02: GetBlockHeadersMessage.self,
        0x03: BlockHeadersMessage.self,
        0x04: GetBlockBodiesMessage.self,
        0x05: BlockBodiesMessage.self,
        0x06: GetReceiptsMessage.self,
        0x07: ReceiptsMessage.self,
        0x0a: GetContractCodesMessage.self,
        0x0b: ContractCodesMessage.self,
        0x0f: GetProofsMessage.self,
        0x10: ProofsMessage.self,
        0x11: GetHelperTrieProofsMessage.self,
        0x12: HelperTrieProofsMessage.self,
        0x13: SendTransactionMessage.self,
        0x14: GetTransactionStatusMessage.self,
        0x15: TransactionStatusMessage.self
    ])

    weak var delegate: IPeerDelegate?

    private let network: INetwork
    private let bestBlock: BlockHeader
    private let devP2PPeer: DevP2PPeer

    var statusSent: Bool = false
    var statusReceived: Bool = false


    init(network: INetwork, bestBlock: BlockHeader, key: ECKey, node: Node, logger: Logger? = nil) {
        self.network = network
        self.bestBlock = bestBlock

        devP2PPeer = DevP2PPeer.instance(key: key, node: node, capability: capability, logger: logger)
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
        guard message.networkId == network.id && message.genesisHash == network.genesisBlockHash else {
            throw LESPeerError.wrongNetwork
        }

        guard message.bestBlockHeight > 0 else {
            throw LESPeerError.peerBestBlockIsLessThanOne
        }

        guard message.bestBlockHeight >= bestBlock.height else {
            throw LESPeerError.peerHasExpiredBlockChain(localHeight: bestBlock.height, peerHeight: message.bestBlockHeight)
        }
    }

    private func handle(message: IMessage) throws {
        switch message {
        case let statusMessage as StatusMessage: handle(message: statusMessage)
        case let blockHeadersMessage as BlockHeadersMessage: handle(message: blockHeadersMessage)
        case let proofsMessage as ProofsMessage: handle(message: proofsMessage)
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

    private func handle(message: ProofsMessage) {
        delegate?.proofReceived(message: message)
    }

}

extension LESPeer: IPeer {

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

    func getBalance(forAddress address: Data, inBlockWithHash blockHash: Data) {
        let message = GetProofsMessage(requestId: Int.random(in: 0..<Int.max), blockHash: blockHash, key: address, key2: Data())

        devP2PPeer.send(message: message)
    }

}

extension LESPeer: IDevP2PPeerDelegate {

    func didEstablishConnection() {
        proceedHandshake()
    }

    func didDisconnect(error: Error?) {
    }

    func didReceive(message: IMessage) {
        do {
            try self.handle(message: message)
        } catch {
            self.disconnect(error: error)
        }
    }

}
