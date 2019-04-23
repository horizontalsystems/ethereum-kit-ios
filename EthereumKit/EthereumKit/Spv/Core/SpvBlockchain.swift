import RxSwift

class SpvBlockchain {
    weak var delegate: IBlockchainDelegate?

    private let peerGroup: IPeerGroup
    private let storage: ISpvStorage
    private let transactionsProvider: ITransactionsProvider
    private let network: INetwork
    private let transactionSigner: TransactionSigner
    private let transactionBuilder: TransactionBuilder

    let address: Data

    private init(peerGroup: IPeerGroup, storage: ISpvStorage, transactionsProvider: ITransactionsProvider, network: INetwork, transactionSigner: TransactionSigner, transactionBuilder: TransactionBuilder, address: Data) {
        self.peerGroup = peerGroup
        self.storage = storage
        self.transactionsProvider = transactionsProvider
        self.network = network
        self.transactionSigner = transactionSigner
        self.transactionBuilder = transactionBuilder
        self.address = address
    }

    private func sendSingle(rawTransaction: RawTransaction, nonce: Int) throws -> Transaction {
        let signature = try transactionSigner.sign(rawTransaction: rawTransaction, nonce: nonce)

        peerGroup.send(rawTransaction: rawTransaction, nonce: nonce, signature: signature)

        return transactionBuilder.transaction(rawTransaction: rawTransaction, nonce: nonce, signature: signature, address: address)
    }

}

extension SpvBlockchain: IBlockchain {

    func start() {
        peerGroup.start()
    }

    func stop() {
        // todo
    }

    func clear() {
        storage.clear()
    }

    var syncState: EthereumKit.SyncState {
        return peerGroup.syncState
    }

    var lastBlockHeight: Int? {
        return storage.lastBlockHeader?.height
    }

    var balance: BInt? {
        return storage.accountState?.balance
    }

    func transactionsSingle(fromHash: Data?, limit: Int?) -> Single<[Transaction]> {
        return storage.transactionsSingle(fromHash: fromHash, limit: limit, contractAddress: nil)
    }

    func sendSingle(rawTransaction: RawTransaction) -> Single<Transaction> {
        let single: Single<Transaction> = Single.create { [unowned self] observer in
            do {
                guard let accountState = self.storage.accountState else {
                    throw SendError.noAccountState
                }

                let transaction = try self.sendSingle(rawTransaction: rawTransaction, nonce: accountState.nonce)

                observer(.success(transaction))
            } catch {
                observer(.error(error))
            }

            return Disposables.create()
        }

        return single.do(onSuccess: { [weak self] transaction in
            self?.storage.save(transactions: [transaction])
            self?.delegate?.onUpdate(transactions: [transaction])
        })
    }

    func getLogsSingle(address: Data?, topics: [Any], fromBlock: Int, toBlock: Int, pullTimestamps: Bool) -> Single<[EthereumLog]> {
        fatalError("getLogsSingle(address:topics:fromBlock:toBlock:pullTimestamps:) has not been implemented")
    }

    func getStorageAt(contractAddress: Data, positionData: Data, blockHeight: Int) -> Single<Data> {
        fatalError("getStorageAt(contractAddress:positionData:blockHeight:) has not been implemented")
    }

}

extension SpvBlockchain: IPeerGroupDelegate {

    func onUpdate(syncState: EthereumKit.SyncState) {
        delegate?.onUpdate(syncState: syncState)
    }

    func onUpdate(accountState: AccountState) {
        storage.save(accountState: accountState)

        delegate?.onUpdate(balance: accountState.balance)
    }

}

extension SpvBlockchain {

    enum SendError: Error {
        case noAccountState
    }

}

extension SpvBlockchain {

    static func instance(storage: ISpvStorage, transactionsProvider: ITransactionsProvider, transactionSigner: TransactionSigner, transactionBuilder: TransactionBuilder, network: INetwork, address: Data, nodeKey: ECKey, logger: Logger? = nil) -> SpvBlockchain {
        let peerProvider = PeerProvider(network: network, storage: storage, connectionKey: nodeKey, logger: logger)
        let validator = BlockValidator()
        let blockHelper = BlockHelper(storage: storage, network: network)
        let peerGroup = PeerGroup(storage: storage, peerProvider: peerProvider, validator: validator, blockHelper: blockHelper, address: address, logger: logger)

        let spvBlockchain = SpvBlockchain(peerGroup: peerGroup, storage: storage, transactionsProvider: transactionsProvider, network: network, transactionSigner: transactionSigner, transactionBuilder: transactionBuilder, address: address)

        peerGroup.delegate = spvBlockchain

        return spvBlockchain
    }

}
