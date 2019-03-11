class LESPeer {
    weak var delegate: ILESPeerDelegate?

    private let devP2PPeer: IDevP2PPeer
    private let messageFactory: IMessageFactory
    private let validator: ILESPeerValidator
    private let network: INetwork
    private let lastBlockHeader: BlockHeader
    private let logger: Logger?

    init(devP2PPeer: IDevP2PPeer, messageFactory: IMessageFactory, validator: ILESPeerValidator, network: INetwork, lastBlockHeader: BlockHeader, logger: Logger? = nil) {
        self.devP2PPeer = devP2PPeer
        self.messageFactory = messageFactory
        self.validator = validator
        self.network = network
        self.lastBlockHeader = lastBlockHeader
        self.logger = logger
    }

    private func handle(message: IMessage) throws {
        switch message {
        case let message as StatusMessage: handle(message: message)
        case let message as BlockHeadersMessage: handle(message: message)
        case let message as ProofsMessage: handle(message: message)
        default: break
        }
    }

    private func handle(message: StatusMessage) {
        do {
            try validator.validate(message: message, network: network, blockHeader: lastBlockHeader)
            delegate?.didConnect()
        } catch {
            disconnect(error: error)
        }
    }

    private func handle(message: BlockHeadersMessage) {
        delegate?.didReceive(blockHeaders: message.headers)
    }

    private func handle(message: ProofsMessage) {
        delegate?.didReceive(proofMessage: message)
    }

}

extension LESPeer: ILESPeer {

    func connect() {
        devP2PPeer.connect()
    }

    func disconnect(error: Error? = nil) {
        devP2PPeer.disconnect(error: error)
    }

    func requestBlockHeaders(fromBlockHash blockHash: Data) {
        let message = messageFactory.getBlockHeadersMessage(blockHash: blockHash)
        devP2PPeer.send(message: message)
    }

    func requestProofs(forAddress address: Data, inBlockWithHash blockHash: Data) {
        let message = messageFactory.getProofsMessage(address: address, blockHash: blockHash)
        devP2PPeer.send(message: message)
    }

}

extension LESPeer: IDevP2PPeerDelegate {

    func didConnect() {
        let statusMessage = messageFactory.statusMessage(network: network, blockHeader: lastBlockHeader)
        devP2PPeer.send(message: statusMessage)
    }

    func didDisconnect(error: Error?) {
        logger?.debug("Disconnected with error: \(error?.localizedDescription ?? "nil")")
    }

    func didReceive(message: IMessage) {
        do {
            try self.handle(message: message)
        } catch {
            self.disconnect(error: error)
        }
    }

}

extension LESPeer {

    static func instance(network: INetwork, lastBlockHeader: BlockHeader, key: ECKey, node: Node, logger: Logger? = nil) -> LESPeer {
        let capability = Capability(name: "les", version: 2, packetTypesMap: [
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

        let devP2PPeer = DevP2PPeer.instance(key: key, node: node, capabilities: [capability], logger: logger)
        let peer = LESPeer(devP2PPeer: devP2PPeer, messageFactory: MessageFactory(), validator: LESPeerValidator(), network: network, lastBlockHeader: lastBlockHeader, logger: logger)

        devP2PPeer.delegate = peer

        return peer
    }

}

extension LESPeer {

    enum ValidationError: Error, Equatable {
        case wrongNetwork
        case peerHasExpiredBlockChain(localHeight: BInt, peerHeight: BInt)
    }

}
