import HsToolKit

class BlockSyncer {
    private let storage: ISpvStorage
    private let blockHelper: IBlockHelper
    private let validator: BlockValidator
    private let headersLimit: Int
    private let logger: Logger?

    weak var delegate: IBlockSyncerDelegate?

    private var syncing = false

    init(storage: ISpvStorage, blockHelper: IBlockHelper, validator: BlockValidator, headersLimit: Int = 50, logger: Logger? = nil) {
        self.storage = storage
        self.blockHelper = blockHelper
        self.validator = validator
        self.headersLimit = headersLimit
        self.logger = logger
    }

    private func onUpdate(taskPerformer: ITaskPerformer, bestBlockHash: Data, bestBlockHeight: Int) {
        guard !syncing else {
            logger?.debug("BlockSyncer: already syncing")
            return
        }

        let lastBlockHeader = blockHelper.lastBlockHeader

        guard lastBlockHeader.height < bestBlockHeight || (lastBlockHeader.height == bestBlockHeight && lastBlockHeader.hashHex != bestBlockHash) else {
            logger?.debug("BlockSyncer: no sync required")
            return
        }

        syncing = true

        taskPerformer.add(task: BlockHeadersTask(blockHeader: lastBlockHeader, limit: headersLimit, reverse: false))
    }

    private func handle(taskPerformer: ITaskPerformer, blockHeaders: [BlockHeader], blockHeader: BlockHeader) throws {
        try validator.validate(blockHeaders: blockHeaders, from: blockHeader)

        storage.save(blockHeaders: blockHeaders)

        guard let lastBlockHeader = blockHeaders.last else {
            return
        }

        delegate?.onUpdate(lastBlockHeader: lastBlockHeader)

        if blockHeaders.count < headersLimit {
            delegate?.onSuccess(taskPerformer: taskPerformer, lastBlockHeader: lastBlockHeader)
            syncing = false
        } else {
            taskPerformer.add(task: BlockHeadersTask(blockHeader: lastBlockHeader, limit: headersLimit, reverse: false))
        }
    }

    private func handleFork(taskPerformer: ITaskPerformer, blockHeaders: [BlockHeader], blockHeader: BlockHeader) throws {
        logger?.debug("Received reversed block headers")

        let storedBlockHeaders = storage.reversedLastBlockHeaders(from: blockHeader.height, limit: blockHeaders.count)

        guard let forkedBlock = storedBlockHeaders.first(where: { storedBlockHeader in
            blockHeaders.contains { $0.hashHex == storedBlockHeader.hashHex && $0.height == storedBlockHeader.height }
        }) else {
            throw PeerError.invalidForkedPeer
        }

        logger?.debug("Found forked block header: \(forkedBlock.height)")

        taskPerformer.add(task: BlockHeadersTask(blockHeader: forkedBlock, limit: headersLimit, reverse: false))
    }

}

extension BlockSyncer: IBlockHeadersTaskHandlerDelegate {

    func didReceive(peer: IPeer, blockHeaders: [BlockHeader], blockHeader: BlockHeader, reverse: Bool) {
        do {
            if reverse {
                try handleFork(taskPerformer: peer, blockHeaders: blockHeaders, blockHeader: blockHeader)
            } else {
                try handle(taskPerformer: peer, blockHeaders: blockHeaders, blockHeader: blockHeader)
            }
        } catch BlockValidator.ValidationError.forkDetected {
            logger?.debug("Fork detected! Requesting reversed headers for block \(blockHeader.height)")

            peer.add(task: BlockHeadersTask(blockHeader: blockHeader, limit: headersLimit, reverse: true))
        } catch {
            delegate?.onFailure(error: error)
            syncing = false
        }
    }

}

extension BlockSyncer: IHandshakeTaskHandlerDelegate {

    func didCompleteHandshake(peer: IPeer, bestBlockHash: Data, bestBlockHeight: Int) {
        onUpdate(taskPerformer: peer, bestBlockHash: bestBlockHash, bestBlockHeight: bestBlockHeight)
    }

}

extension BlockSyncer: IAnnouncedBlockHandlerDelegate {

    func didAnnounce(peer: IPeer, blockHash: Data, blockHeight: Int) {
        onUpdate(taskPerformer: peer, bestBlockHash: blockHash, bestBlockHeight: blockHeight)
    }

}


extension BlockSyncer {

    enum PeerError: Error {
        case invalidForkedPeer
    }

}

protocol IBlockSyncerDelegate: AnyObject {
    func onSuccess(taskPerformer: ITaskPerformer, lastBlockHeader: BlockHeader)
    func onFailure(error: Error)

    func onUpdate(lastBlockHeader: BlockHeader)
}
