import RxSwift
import BigInt

class SpvBlockchain {
    weak var delegate: IBlockchainDelegate?

    private let peer: IPeer
    private let blockSyncer: BlockSyncer
    private let accountStateSyncer: AccountStateSyncer
    private let transactionSender: TransactionSender
    private let storage: ISpvStorage
    private let network: INetwork
    private let rpcApiProvider: IRpcApiProvider
    private let logger: Logger?

    private var sendingTransactions = [Int: PublishSubject<Transaction>]()

    private init(peer: IPeer, blockSyncer: BlockSyncer, accountStateSyncer: AccountStateSyncer, transactionSender: TransactionSender, storage: ISpvStorage, network: INetwork, rpcApiProvider: IRpcApiProvider, logger: Logger? = nil) {
        self.peer = peer
        self.blockSyncer = blockSyncer
        self.accountStateSyncer = accountStateSyncer
        self.transactionSender = transactionSender
        self.storage = storage
        self.network = network
        self.rpcApiProvider = rpcApiProvider
        self.logger = logger
    }

}

extension SpvBlockchain: IBlockchain {

    func start() {
        logger?.verbose("SpvBlockchain started")

        peer.connect()
    }

    func stop() {
        logger?.verbose("SpvBlockchain stopped")

        // todo
    }

    func refresh() {
        // todo
    }

    var syncState: EthereumKit.SyncState {
        return .notSynced
    }

    var lastBlockHeight: Int? {
        return storage.lastBlockHeader?.height
    }

    var balance: BigUInt? {
        return storage.accountState?.balance
    }

    func sendSingle(rawTransaction: RawTransaction) -> Single<Transaction> {
        let sendId = RandomHelper.shared.randomInt

        do {
            try transactionSender.send(sendId: sendId, taskPerformer: peer, rawTransaction: rawTransaction)

            let subject = PublishSubject<Transaction>()
            sendingTransactions[sendId] = subject
            return subject.asSingle()
        } catch {
            return Single.error(error)
        }
    }

    func getLogsSingle(address: Data?, topics: [Any?], fromBlock: Int, toBlock: Int, pullTimestamps: Bool) -> Single<[EthereumLog]> {
        return Single.just([])
    }

    func getStorageAt(contractAddress: Data, positionData: Data, blockHeight: Int) -> Single<Data> {
        return Single.just(Data())
    }

    func call(contractAddress: Data, data: Data, blockHeight: Int?) -> Single<Data> {
        return rpcApiProvider.call(contractAddress: contractAddress.toHexString(), data: data.toHexString(), blockNumber: blockHeight)
                .flatMap { value -> Single<Data> in
                    guard let data = Data(hex: value) else {
                        return Single.error(EthereumKit.ApiError.invalidData)
                    }

                    return Single.just(data)
                }
    }

}

extension SpvBlockchain: IPeerDelegate {

    func didConnect(peer: IPeer) {
        let lastBlockHeader = storage.lastBlockHeader ?? network.checkpointBlock
        peer.add(task: HandshakeTask(peerId: peer.id, network: network, blockHeader: lastBlockHeader))
    }

    func didDisconnect(peer: IPeer, error: Error?) {
    }

}

extension SpvBlockchain: IBlockSyncerDelegate {

    func onSuccess(taskPerformer: ITaskPerformer, lastBlockHeader: BlockHeader) {
        logger?.debug("Blocks synced successfully up to \(lastBlockHeader.height). Starting account state sync...")

        accountStateSyncer.sync(taskPerformer: taskPerformer, blockHeader: lastBlockHeader)
    }

    func onFailure(error: Error) {
        logger?.error("Blocks sync failed: \(error)")
    }

    func onUpdate(lastBlockHeader: BlockHeader) {
        delegate?.onUpdate(lastBlockHeight: lastBlockHeader.height)
    }

}

extension SpvBlockchain: IAccountStateSyncerDelegate {

    func onUpdate(accountState: AccountState) {
        delegate?.onUpdate(balance: accountState.balance)
    }

}

extension SpvBlockchain: ITransactionSenderDelegate {

    func onSendSuccess(sendId: Int, transaction: Transaction) {
        guard let subject = sendingTransactions.removeValue(forKey: sendId) else {
            return
        }

        subject.onNext(transaction)
        subject.onCompleted()
    }

    func onSendFailure(sendId: Int, error: Error) {
        guard let subject = sendingTransactions.removeValue(forKey: sendId) else {
            return
        }

        subject.onError(error)
    }

}

extension SpvBlockchain {

    static func instance(storage: ISpvStorage, transactionSigner: TransactionSigner, transactionBuilder: TransactionBuilder, rpcApiProvider: IRpcApiProvider, network: INetwork, address: Data, nodeKey: ECKey, logger: Logger? = nil) -> SpvBlockchain {
        let validator = BlockValidator()
        let blockHelper = BlockHelper(storage: storage, network: network)

        let peerProvider = PeerProvider(network: network, connectionKey: nodeKey, logger: logger)

        let peer = PeerGroup(peerProvider: peerProvider, logger: logger)
//        let peer = peerProvider.peer()

        let blockSyncer = BlockSyncer(storage: storage, blockHelper: blockHelper, validator: validator, logger: logger)
        let accountStateSyncer = AccountStateSyncer(storage: storage, address: address)
        let transactionSender = TransactionSender(storage: storage, transactionBuilder: transactionBuilder, transactionSigner: transactionSigner)

        let spvBlockchain = SpvBlockchain(peer: peer, blockSyncer: blockSyncer, accountStateSyncer: accountStateSyncer, transactionSender: transactionSender, storage: storage, network: network, rpcApiProvider: rpcApiProvider, logger: logger)

        peer.delegate = spvBlockchain
        blockSyncer.delegate = spvBlockchain
        accountStateSyncer.delegate = spvBlockchain
        transactionSender.delegate = spvBlockchain

        let handshakeHandler = HandshakeTaskHandler(delegate: blockSyncer)
        peer.register(taskHandler: handshakeHandler)
        peer.register(messageHandler: handshakeHandler)

        let blockHeadersHandler = BlockHeadersTaskHandler(delegate: blockSyncer)
        peer.register(taskHandler: blockHeadersHandler)
        peer.register(messageHandler: blockHeadersHandler)

        let accountStateHandler = AccountStateTaskHandler(delegate: accountStateSyncer)
        peer.register(taskHandler: accountStateHandler)
        peer.register(messageHandler: accountStateHandler)

        let sendTransactionHandler = SendTransactionTaskHandler(delegate: transactionSender)
        peer.register(taskHandler: sendTransactionHandler)
        peer.register(messageHandler: sendTransactionHandler)

        peer.register(messageHandler: AnnouncedBlockHandler(delegate: blockSyncer))

        return spvBlockchain
    }

}
