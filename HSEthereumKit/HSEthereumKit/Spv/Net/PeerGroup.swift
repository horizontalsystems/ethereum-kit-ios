class PeerGroup {
    weak var delegate: IPeerGroupDelegate?

    private let storage: ISpvStorage
    private let peerProvider: IPeerProvider
    private let validator: BlockValidator
    private let blockHelper: IBlockHelper
    private let state: PeerGroupState
    private let addressData: Data
    private let headersLimit: Int
    private let logger: Logger?

    init(
            storage: ISpvStorage,
            peerProvider: IPeerProvider,
            validator: BlockValidator,
            blockHelper: IBlockHelper,
            state: PeerGroupState = PeerGroupState(),
            addressData: Data,
            headersLimit: Int = 50,
            logger: Logger? = nil
    ) {
        self.storage = storage
        self.peerProvider = peerProvider
        self.validator = validator
        self.blockHelper = blockHelper
        self.state = state
        self.addressData = addressData
        self.headersLimit = headersLimit
        self.logger = logger
    }

    private func handle(blockHeaders: [BlockHeader], blockHeader: BlockHeader) throws {
        try validator.validate(blockHeaders: blockHeaders, from: blockHeader)

        storage.save(blockHeaders: blockHeaders)

        guard let lastBlockHeader = blockHeaders.last else {
            return
        }

        if blockHeaders.count < headersLimit {
            state.syncPeer?.requestAccountState(address: addressData, blockHeader: lastBlockHeader)
        } else {
            state.syncPeer?.requestBlockHeaders(blockHeader: lastBlockHeader, limit: headersLimit, reverse: false)
        }
    }

    private func handleFork(blockHeaders: [BlockHeader], blockHeader: BlockHeader) throws {
        logger?.debug("Received reversed block headers")

        let storedBlockHeaders = storage.reversedLastBlockHeaders(from: blockHeader.height, limit: blockHeaders.count)

        guard let forkedBlock = storedBlockHeaders.first(where: { storedBlockHeader in
            blockHeaders.contains { $0.hashHex == storedBlockHeader.hashHex && $0.height == storedBlockHeader.height }
        }) else {
            throw PeerError.invalidForkedPeer
        }

        logger?.debug("Found forked block header: \(forkedBlock.height)")

        state.syncPeer?.requestBlockHeaders(blockHeader: forkedBlock, limit: headersLimit, reverse: false)
    }

}

extension PeerGroup: IPeerGroup {

    var syncState: EthereumKit.SyncState {
        return state.syncState
    }

    func start() {
        state.syncState = .syncing
        delegate?.onUpdate(syncState: .syncing)

        let peer = peerProvider.peer()
        peer.delegate = self

        state.syncPeer = peer
        peer.connect()
    }

    func send(rawTransaction: RawTransaction, nonce: Int, signature: Signature) {
        state.syncPeer?.send(rawTransaction: rawTransaction, nonce: nonce, signature: signature)
    }

}

extension PeerGroup: IPeerDelegate {

    func didConnect() {
        state.syncPeer?.requestBlockHeaders(blockHeader: blockHelper.lastBlockHeader, limit: headersLimit, reverse: false)
    }

    func didDisconnect(error: Error?) {
        state.syncPeer = nil
    }

    func didReceive(blockHeaders: [BlockHeader], blockHeader: BlockHeader, reverse: Bool) {
        do {
            if reverse {
                try handleFork(blockHeaders: blockHeaders, blockHeader: blockHeader)
            } else {
                try handle(blockHeaders: blockHeaders, blockHeader: blockHeader)
            }
        } catch BlockValidator.ValidationError.forkDetected {
            logger?.debug("Fork detected! Requesting reversed headers for block \(blockHeader.height)")

            state.syncPeer?.requestBlockHeaders(blockHeader: blockHeader, limit: headersLimit, reverse: true)
        } catch {
            state.syncPeer?.disconnect(error: error)
        }
    }

    func didReceive(accountState: AccountState, address: Data, blockHeader: BlockHeader) {
        logger?.verbose("ACCOUNT STATE: \(accountState.toString())")

        delegate?.onUpdate(accountState: accountState)

        state.syncState = .synced
        delegate?.onUpdate(syncState: .synced)
    }

    func didAnnounce(blockHash: Data, blockHeight: Int) {
        guard state.syncState == .synced else {
            return
        }

        state.syncPeer?.requestBlockHeaders(blockHeader: blockHelper.lastBlockHeader, limit: headersLimit, reverse: false)
    }

}

extension PeerGroup {

    enum PeerError: Error {
        case invalidForkedPeer
    }

}
