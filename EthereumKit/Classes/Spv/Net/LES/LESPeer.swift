import HsToolKit

class LESPeer {
    weak var delegate: IPeerDelegate?

    private let devP2PPeer: IDevP2PPeer
    private let logger: Logger?

    private var taskHandlers = [ITaskHandler]()
    private var messageHandlers = [IMessageHandler]()

    private var bestBlock: (hash: Data, height: Int)?

    init(devP2PPeer: IDevP2PPeer, logger: Logger? = nil) {
        self.devP2PPeer = devP2PPeer
        self.logger = logger
    }

    private func log(_ message: String, level: Logger.Level = .debug) {
        logger?.log(level: level, message: message, context: [devP2PPeer.logName])
    }

}

extension LESPeer: IPeer {

    var id: String {
        return devP2PPeer.logName
    }

    func register(taskHandler: ITaskHandler) {
        taskHandlers.append(taskHandler)
    }

    func register(messageHandler: IMessageHandler) {
        messageHandlers.append(messageHandler)
    }

    func connect() {
        devP2PPeer.connect()
    }

    func disconnect(error: Error? = nil) {
        devP2PPeer.disconnect(error: error)
    }

    func add(task: ITask) {
        for taskHandler in taskHandlers {
            if taskHandler.perform(task: task, requester: self) {
                return
            }
        }

        log("No handler for task: \(task)", level: .warning)
    }

}

extension LESPeer: IDevP2PPeerDelegate {

    func didConnect() {
        delegate?.didConnect(peer: self)
    }

    func didDisconnect(error: Error?) {
        log("Disconnected with error: \(error.map { "\($0)" } ?? "nil")", level: .error)

        delegate?.didDisconnect(peer: self, error: error)
    }

    func didReceive(message: IInMessage) {
        do {
            for messageHandler in messageHandlers {
                if try messageHandler.handle(peer: self, message: message) {
                    return
                }
            }

            log("No handler for message: \(message)", level: .warning)
        } catch {
            disconnect(error: error)
        }
    }

}

extension LESPeer: ITaskHandlerRequester {

    func send(message: IOutMessage) {
        devP2PPeer.send(message: message)
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

    static func instance(key: ECKey, node: Node, logger: Logger? = nil) -> LESPeer {
        let devP2PPeer = DevP2PPeer.instance(key: key, node: node, capabilities: [capability], logger: logger)
        let peer = LESPeer(devP2PPeer: devP2PPeer, logger: logger)

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
