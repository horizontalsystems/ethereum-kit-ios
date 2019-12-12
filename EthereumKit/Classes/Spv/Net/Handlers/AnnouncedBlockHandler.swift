protocol IAnnouncedBlockHandlerDelegate: AnyObject {
    func didAnnounce(peer: IPeer, blockHash: Data, blockHeight: Int)
}

class AnnouncedBlockHandler {
    weak var delegate: IAnnouncedBlockHandlerDelegate?

    init(delegate: IAnnouncedBlockHandlerDelegate?) {
        self.delegate = delegate
    }

}

extension AnnouncedBlockHandler: IMessageHandler {

    func handle(peer: IPeer, message: IInMessage) throws -> Bool {
        guard let message = message as? AnnounceMessage else {
            return false
        }

        delegate?.didAnnounce(peer: peer, blockHash: message.blockHash, blockHeight: message.blockHeight)

        return true
    }

}
