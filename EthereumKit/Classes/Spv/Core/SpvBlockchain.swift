import RxSwift
import BigInt
import HsToolKit

class SpvBlockchain {
    weak var delegate: IBlockchainDelegate?

    private let peer: IPeer
    private let blockSyncer: BlockSyncer
    private let nodeManager: NodeManager
    private let accountStateSyncer: AccountStateSyncer
    private let transactionSender: TransactionSender
    private let storage: ISpvStorage
    private let network: INetwork
//    private let rpcApiProvider: IRpcApiProvider
    private let logger: Logger?

    private var sendingTransactions = [Int: PublishSubject<Transaction>]()

    private init(peer: IPeer, blockSyncer: BlockSyncer, nodeManager: NodeManager, accountStateSyncer: AccountStateSyncer, transactionSender: TransactionSender, storage: ISpvStorage, network: INetwork, logger: Logger? = nil) {
        self.peer = peer
        self.blockSyncer = blockSyncer
        self.nodeManager = nodeManager
        self.accountStateSyncer = accountStateSyncer
        self.transactionSender = transactionSender
        self.storage = storage
        self.network = network
//        self.rpcApiProvider = rpcApiProvider
        self.logger = logger
    }

}

extension SpvBlockchain: IBlockchain {

    var source: String {
        "SPV"
    }

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

    func syncAccountState() {
    }

    var syncState: SyncState {
        .notSynced(error: SyncError.stubError)
    }

    var lastBlockHeight: Int? {
        storage.lastBlockHeader?.height
    }

    var accountState: AccountState? {
        storage.accountState.map { AccountState(balance: $0.balance, nonce: $0.nonce) }
    }

    var nonce: Int? {
        storage.accountState?.nonce
    }

    func nonceSingle(defaultBlockParameter: DefaultBlockParameter) -> Single<Int> {
        guard let nonce = storage.accountState?.nonce else {
            return Single.error(Kit.SendError.noAccountState)
        }

        return Single.just(nonce)
    }

    func sendSingle(rawTransaction: RawTransaction, signature: Signature) -> Single<Transaction> {
        let sendId = RandomHelper.shared.randomInt

        transactionSender.send(sendId: sendId, taskPerformer: peer, rawTransaction: rawTransaction, signature: signature)

        let subject = PublishSubject<Transaction>()
        sendingTransactions[sendId] = subject
        return subject.asSingle()
    }

    func getLogsSingle(address: Address?, topics: [Any?], fromBlock: Int, toBlock: Int, pullTimestamps: Bool) -> Single<[TransactionLog]> {
        Single.just([])
    }

    func transactionReceiptSingle(transactionHash: Data) -> Single<RpcTransactionReceipt> {
        fatalError("Not implemented yet")
//        rpcApiProvider.transactionReceiptStatusSingle(transactionHash: transactionHash)
    }

    func transactionSingle(transactionHash: Data) -> Single<RpcTransaction> {
        fatalError("Not implemented yet")
//        rpcApiProvider.transactionExistSingle(transactionHash: transactionHash)
    }

    func getStorageAt(contractAddress: Address, positionData: Data, defaultBlockParameter: DefaultBlockParameter) -> Single<Data> {
        Single.just(Data())
    }

    func call(contractAddress: Address, data: Data, defaultBlockParameter: DefaultBlockParameter) -> Single<Data> {
        fatalError("Not implemented yet")
//        rpcApiProvider.call(contractAddress: contractAddress, data: data, defaultBlockParameter: defaultBlockParameter)
    }

    func estimateGas(to: Address?, amount: BigUInt?, gasLimit: Int?, gasPrice: GasPrice, data: Data?) -> Single<Int> {
        fatalError("Not implemented yet")
//        rpcApiProvider.getEstimateGas(to: to, amount: amount, gasLimit: gasLimit, gasPrice: gasPrice, data: data)
    }

    func getBlock(blockNumber: Int) -> Single<RpcBlock> {
        fatalError("Not implemented yet")
    }

    func rpcSingle<T>(rpcRequest: JsonRpc<T>) -> Single<T> {
        fatalError("Not implemented yet")
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

    func onUpdate(accountState: AccountStateSpv) {
        delegate?.onUpdate(accountState: AccountState(balance: accountState.balance, nonce: accountState.nonce))
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

    static func instance(storage: ISpvStorage, nodeManager: NodeManager, transactionBuilder: TransactionBuilder, network: INetwork, address: Address, nodeKey: ECKey, logger: Logger? = nil) -> SpvBlockchain {
        let validator = BlockValidator()
        let blockHelper = BlockHelper(storage: storage, network: network)

        let peerProvider = PeerProvider(network: network, connectionKey: nodeKey, logger: logger)

        let peer = PeerGroup(peerProvider: peerProvider, logger: logger)
//        let peer = peerProvider.peer()

        let blockSyncer = BlockSyncer(storage: storage, blockHelper: blockHelper, validator: validator, logger: logger)
        let accountStateSyncer = AccountStateSyncer(storage: storage, address: address)
        let transactionSender = TransactionSender(storage: storage, transactionBuilder: transactionBuilder)

        let spvBlockchain = SpvBlockchain(peer: peer, blockSyncer: blockSyncer, nodeManager: nodeManager, accountStateSyncer: accountStateSyncer, transactionSender: transactionSender, storage: storage, network: network, logger: logger)

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

extension SpvBlockchain {

    public enum SyncError: Error {
        case stubError
    }

}
