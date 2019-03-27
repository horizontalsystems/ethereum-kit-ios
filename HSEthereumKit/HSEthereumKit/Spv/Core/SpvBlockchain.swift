import RxSwift

class SpvBlockchain {
    weak var delegate: IBlockchainDelegate?

    private let peerGroup: IPeerGroup
    private let storage: ISpvStorage
    private let network: INetwork
    private let transactionSigner: TransactionSigner
    private let transactionBuilder: TransactionBuilder

    let address: Address

    private init(peerGroup: IPeerGroup, storage: ISpvStorage, network: INetwork, transactionSigner: TransactionSigner, transactionBuilder: TransactionBuilder, address: Address) {
        self.peerGroup = peerGroup
        self.storage = storage
        self.network = network
        self.transactionSigner = transactionSigner
        self.transactionBuilder = transactionBuilder
        self.address = address
    }

    private func sendSingle(rawTransaction: RawTransaction, nonce: Int) throws -> EthereumTransaction {
        let signature = try transactionSigner.sign(rawTransaction: rawTransaction, nonce: nonce)

        peerGroup.send(rawTransaction: rawTransaction, nonce: nonce, signature: signature)

        return transactionBuilder.transaction(rawTransaction: rawTransaction, nonce: nonce, signature: signature, address: address)
    }

}

extension SpvBlockchain: IBlockchain {

    func start() {
        peerGroup.start()
    }

    func clear() {
        storage.clear()
    }

    var syncState: EthereumKit.SyncState {
        return peerGroup.syncState
    }

    func syncStateErc20(contractAddress: String) -> EthereumKit.SyncState {
        return EthereumKit.SyncState.synced
    }

    var lastBlockHeight: Int? {
        return storage.lastBlockHeader?.height
    }

    var balance: String? {
        return storage.accountState?.balance.asString(withBase: 10)
    }

    func balanceErc20(contractAddress: String) -> String? {
        return nil
    }

    func transactionsSingle(fromHash: String?, limit: Int?) -> Single<[EthereumTransaction]> {
        return storage.transactionsSingle(fromHash: fromHash, limit: limit, contractAddress: nil)
    }

    func transactionsErc20Single(contractAddress: String, fromHash: String?, limit: Int?) -> Single<[EthereumTransaction]> {
        return storage.transactionsSingle(fromHash: fromHash, limit: limit, contractAddress: contractAddress)
    }

    func sendSingle(rawTransaction: RawTransaction) -> Single<EthereumTransaction> {
        let single: Single<EthereumTransaction> = Single.create { [unowned self] observer in
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

    func register(contractAddress: String) {
    }

    func unregister(contractAddress: String) {
    }

}

extension SpvBlockchain: IPeerGroupDelegate {

    func onUpdate(syncState: EthereumKit.SyncState) {
        delegate?.onUpdate(syncState: syncState)
    }

    func onUpdate(accountState: AccountState) {
        storage.save(accountState: accountState)

        delegate?.onUpdate(balance: accountState.balance.asString(withBase: 10))
    }

}

extension SpvBlockchain {

    enum SendError: Error {
        case noAccountState
    }

}

extension SpvBlockchain {

    static func spvBlockchain(storage: ISpvStorage, transactionSigner: TransactionSigner, transactionBuilder: TransactionBuilder, network: INetwork, address: Address, nodeKey: ECKey, logger: Logger? = nil) -> SpvBlockchain {
        let peerProvider = PeerProvider(network: network, storage: storage, connectionKey: nodeKey, logger: logger)
        let validator = BlockValidator()
        let blockHelper = BlockHelper(storage: storage, network: network)
        let peerGroup = PeerGroup(storage: storage, peerProvider: peerProvider, validator: validator, blockHelper: blockHelper, addressData: address.data, logger: logger)

        let spvBlockchain = SpvBlockchain(peerGroup: peerGroup, storage: storage, network: network, transactionSigner: transactionSigner, transactionBuilder: transactionBuilder, address: address)

        peerGroup.delegate = spvBlockchain

        return spvBlockchain
    }

}
