import HsToolKit

class PeerGroup {
    weak var delegate: IPeerDelegate?

    private let peerProvider: IPeerProvider
    private let logger: Logger?

    private var peers = [IPeer]()

    init(peerProvider: IPeerProvider, logger: Logger? = nil) {
        self.peerProvider = peerProvider
        self.logger = logger

        peers.append(configure(peer: peerProvider.peer()))
    }

    private func configure(peer: IPeer) -> IPeer {
        peer.delegate = self

        return peer
    }

}

extension PeerGroup: IPeer {

    var id: String {
        fatalError("id has not been implemented")
    }

    func register(messageHandler: IMessageHandler) {
        for peer in peers {
            peer.register(messageHandler: messageHandler)
        }
    }

    func connect() {
        for peer in peers {
            peer.connect()
        }
    }

    func register(taskHandler: ITaskHandler) {
        for peer in peers {
            peer.register(taskHandler: taskHandler)
        }
    }

    func add(task: ITask) {
        guard let peer = peers.first else {
            return
        }

        peer.add(task: task)
    }

}

extension PeerGroup: IPeerDelegate {

    func didConnect(peer: IPeer) {
        delegate?.didConnect(peer: peer)
    }

    func didDisconnect(peer: IPeer, error: Error?) {
    }

}
