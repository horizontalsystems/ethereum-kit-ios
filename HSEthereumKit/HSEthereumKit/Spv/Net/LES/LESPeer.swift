class LESPeer {
    weak var delegate: ILESPeerDelegate?

    private let devP2PPeer: IDevP2PPeer
    private let requestHolder: LESPeerRequestHolder
    private let randomHelper: IRandomHelper
    private let network: INetwork
    private let lastBlockHeader: BlockHeader
    private let logger: Logger?

    init(devP2PPeer: IDevP2PPeer, requestHolder: LESPeerRequestHolder = LESPeerRequestHolder(), randomHelper: IRandomHelper = RandomHelper.shared, network: INetwork, lastBlockHeader: BlockHeader, logger: Logger? = nil) {
        self.devP2PPeer = devP2PPeer
        self.requestHolder = requestHolder
        self.randomHelper = randomHelper
        self.network = network
        self.lastBlockHeader = lastBlockHeader
        self.logger = logger
    }

    private func handle(message: IInMessage) throws {
        switch message {
        case let message as StatusMessage: try handle(message: message)
        case let message as BlockHeadersMessage: try handle(message: message)
        case let message as ProofsMessage: try handle(message: message)
        case let message as AnnounceMessage: try handle(message: message)
        default: logger?.warning("Unknown message: \(message)")
        }
    }

    private func handle(message: StatusMessage) throws {
        guard message.protocolVersion == LESPeer.capability.version else {
            throw LESPeer.ValidationError.invalidProtocolVersion
        }

        guard message.networkId == network.id else {
            throw LESPeer.ValidationError.wrongNetwork
        }

        guard message.genesisHash == network.genesisBlockHash else {
            throw LESPeer.ValidationError.wrongNetwork
        }

        guard message.headHeight >= lastBlockHeader.height else {
            throw LESPeer.ValidationError.expiredBestBlockHeight
        }

        delegate?.didConnect()
    }

    private func handle(message: BlockHeadersMessage) throws {
        guard let request = requestHolder.removeBlockHeaderRequest(id: message.requestId) else {
            throw LESPeer.ConsistencyError.unexpectedMessage
        }

        delegate?.didReceive(blockHeaders: message.headers, blockHash: request.blockHash)
    }

    private func handle(message: ProofsMessage) throws {
        guard let request = requestHolder.removeAccountStateRequest(id: message.requestId) else {
            throw LESPeer.ConsistencyError.unexpectedMessage
        }

        let accountState = try request.accountState(proofsMessage: message)
        delegate?.didReceive(accountState: accountState, address: request.address, blockHeader: request.blockHeader)
    }

    private func handle(message: AnnounceMessage) throws {
        delegate?.didAnnounce(blockHash: message.blockHash, blockHeight: message.blockHeight)
    }

}

extension LESPeer: ILESPeer {

    func connect() {
        devP2PPeer.connect()
    }

    func disconnect(error: Error? = nil) {
        devP2PPeer.disconnect(error: error)
    }

    func requestBlockHeaders(blockHash: Data) {
        let requestId = randomHelper.randomInt
        let request = BlockHeaderRequest(blockHash: blockHash)
        let message = GetBlockHeadersMessage(requestId: requestId, blockHash: blockHash)

        requestHolder.set(blockHeaderRequest: request, id: requestId)
        devP2PPeer.send(message: message)
    }

    func requestAccountState(address: Data, blockHeader: BlockHeader) {
        let requestId = randomHelper.randomInt
        let request = AccountStateRequest(address: address, blockHeader: blockHeader)
        let message = GetProofsMessage(requestId: requestId, blockHash: blockHeader.hashHex, key: address)

        requestHolder.set(accountStateRequest: request, id: requestId)
        devP2PPeer.send(message: message)
    }

}

extension LESPeer: IDevP2PPeerDelegate {

    func didConnect() {
        let statusMessage = StatusMessage(
                protocolVersion: LESPeer.capability.version,
                networkId: network.id,
                genesisHash: network.genesisBlockHash,
                headTotalDifficulty: lastBlockHeader.totalDifficulty,
                headHash: lastBlockHeader.hashHex,
                headHeight: lastBlockHeader.height
        )

        devP2PPeer.send(message: statusMessage)

    }

    func didDisconnect(error: Error?) {
        logger?.debug("Disconnected with error: \(error?.localizedDescription ?? "nil")")
    }

    func didReceive(message: IInMessage) {
        do {
            try handle(message: message)
        } catch {
            disconnect(error: error)
        }
    }

}

extension LESPeer {

    static let capability = Capability(name: "les", version: 2, packetTypesMap: [
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

    static func instance(network: INetwork, lastBlockHeader: BlockHeader, key: ECKey, node: Node, logger: Logger? = nil) -> LESPeer {
        let devP2PPeer = DevP2PPeer.instance(key: key, node: node, capabilities: [capability], logger: logger)
        let peer = LESPeer(devP2PPeer: devP2PPeer, network: network, lastBlockHeader: lastBlockHeader, logger: logger)

        devP2PPeer.delegate = peer

        return peer
    }

}

extension LESPeer {

    enum ValidationError: Error, Equatable {
        case invalidProtocolVersion
        case wrongNetwork
        case expiredBestBlockHeight
    }

    enum ConsistencyError: Error, Equatable {
        case unexpectedMessage
    }

}
