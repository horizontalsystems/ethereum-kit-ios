import RxSwift
import BigInt
import Geth

class GethBlockchain: NSObject {
    private let disposeBag = DisposeBag()

    weak var delegate: IBlockchainDelegate?

    private let network: INetwork
    private let storage: IApiStorage
    private let transactionSigner: TransactionSigner
    private let transactionBuilder: TransactionBuilder
    private let logger: Logger?

    private let account: GethAddress?

    private let context: GethContext
    private let node: GethNode

    private let lastBlockHeightSubject = PublishSubject<Int>()

    private(set) var syncState: EthereumKit.SyncState = .syncing(progress: nil) {
        didSet {
            if syncState != oldValue {
                delegate?.onUpdate(syncState: syncState)
            }
        }
    }

    private init(network: INetwork, storage: IApiStorage, transactionSigner: TransactionSigner, transactionBuilder: TransactionBuilder, address: Data, logger: Logger? = nil) throws {
        self.network = network
        self.storage = storage
        self.transactionSigner = transactionSigner
        self.transactionBuilder = transactionBuilder
        self.logger = logger

        account = GethAddress(fromBytes: address)

        guard let context = GethContext() else {
            throw InitError.contextFailed
        }

        self.context = context

        var error: NSError?

        let config = GethNewNodeConfig()
        config?.ethereumGenesis = network is Ropsten ? GethTestnetGenesis() : GethMainnetGenesis()
        config?.ethereumNetworkID = Int64(network.chainId)
        config?.bootstrapNodes = GethFoundationBootnodes()
        config?.ethereumEnabled = true
        config?.maxPeers = 25
        config?.whisperEnabled = false

        let fileManager = FileManager.default

        let nodeDir = try! fileManager
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("geth", isDirectory: true)

        guard let node = GethNewNode(nodeDir.path, config, &error) else {
            throw InitError.nodeFailed
        }

        self.node = node

        super.init()

        lastBlockHeightSubject.throttle(1, scheduler: ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onNext: { [weak self] in
                    self?.update(lastBlockHeight: $0)
                })
                .disposed(by: disposeBag)
    }

    private func update(lastBlockHeight: Int) {
        storage.save(lastBlockHeight: lastBlockHeight)
        delegate?.onUpdate(lastBlockHeight: lastBlockHeight)

        do {
            let syncProgress = try node.getEthereumClient().syncProgress(context)

            let startingBlock = Double(syncProgress.getStartingBlock())
            let highestBlock = Double(syncProgress.getHighestBlock())
            let currentBlock = Double(syncProgress.getCurrentBlock())

            let progress = (currentBlock - startingBlock) / (highestBlock - startingBlock)

            syncState = .syncing(progress: progress)
        } catch {
            let peersCount = node.getPeersInfo()?.size() ?? 0

            if peersCount == 0 {
                syncState = .syncing(progress: nil)
            } else {
                syncState = .synced

                syncAccountState()
            }
        }
    }

    private func syncAccountState() {
        do {
            let gethBalance = try node.getEthereumClient().getBalanceAt(context, account: account, number: -1)

            guard let balance = BigUInt(gethBalance.string()) else {
                return
            }

            update(balance: balance)
        } catch {
            logger?.error("Could not fetch account state: \(error)")
        }
    }

    private func update(balance: BigUInt) {
        storage.save(balance: balance)
        delegate?.onUpdate(balance: balance)
    }

    private func send(rawTransaction: RawTransaction) throws -> Transaction {
        var nonce: Int64 = 0
        try node.getEthereumClient().getNonceAt(context, account: account, number: -1, nonce: &nonce)

        logger?.info("NONCE: \(nonce)")

        let toAccount = GethAddress(fromBytes: rawTransaction.to)

        let amount = GethBigInt(0)
        amount?.setString(rawTransaction.value.description, base: 10)

        let gethTransaction = GethTransaction(
                nonce,
                to: toAccount,
                amount: amount,
                gasLimit: Int64(rawTransaction.gasLimit),
                gasPrice: GethBigInt(Int64(rawTransaction.gasPrice)),
                data: rawTransaction.data
        )

        let signature = try transactionSigner.sign(rawTransaction: rawTransaction, nonce: Int(nonce))
        let signedTransaction = try gethTransaction?.withSignature(signature, chainID: GethBigInt(Int64(network.chainId)))

        try node.getEthereumClient().sendTransaction(context, tx: signedTransaction)

        return transactionBuilder.transaction(rawTransaction: rawTransaction, nonce: Int(nonce), signature: transactionSigner.signature(from: signature))
    }

}

extension GethBlockchain: IBlockchain {

    func start() {
        do {
            try node.start()
            logger?.verbose("GethBlockchain: started")
        } catch {
            logger?.error("GethBlockchain: failed to start node: \(error)")
        }

        do {
            try node.getEthereumClient().subscribeNewHead(context, handler: self, buffer: 16)
            logger?.verbose("GethBlockchain: subscribed to new headers")
        } catch {
            logger?.error("GethBlockchain: failed to subscribe to new headers: \(error)")
        }
    }

    func stop() {
        do {
            try node.stop()
            logger?.verbose("GethBlockchain: stopped")
        } catch {
            logger?.error("GethBlockchain: failed to stop node: \(error)")
        }
    }

    func refresh() {
    }

    var lastBlockHeight: Int? {
        return storage.lastBlockHeight
    }

    var balance: BigUInt? {
        return storage.balance
    }

    func transactionsSingle(fromHash: Data?, limit: Int?) -> Single<[Transaction]> {
        return Single.just([])
    }

    func sendSingle(rawTransaction: RawTransaction) -> Single<Transaction> {
        return Single.create { [unowned self] observer in
            do {
                let transaction = try self.send(rawTransaction: rawTransaction)

                observer(.success(transaction))
            } catch {
                self.logger?.error("Send error: \(error)")

                observer(.error(error))
            }

            return Disposables.create()
        }
    }

    func getLogsSingle(address: Data?, topics: [Any], fromBlock: Int, toBlock: Int, pullTimestamps: Bool) -> Single<[EthereumLog]> {
        return Single.just([])
    }

    func getStorageAt(contractAddress: Data, positionData: Data, blockHeight: Int) -> Single<Data> {
        return Single.just(Data())
    }

    func call(contractAddress: Data, data: Data, blockHeight: Int?) -> Single<Data> {
        fatalError()
    }

}

extension GethBlockchain: GethNewHeadHandlerProtocol {

    public func onNewHead(_ header: GethHeader?) {
        guard let blockNumber = header?.getNumber() else {
            return
        }

        lastBlockHeightSubject.onNext(Int(blockNumber))
    }

    public func onError(_ failure: String?) {
        print("NEW HEAD ERROR: \(failure ?? "nil")")
    }

}

extension GethBlockchain {

    static func instance(network: INetwork, storage: IApiStorage, transactionSigner: TransactionSigner, transactionBuilder: TransactionBuilder, address: Data, logger: Logger? = nil) throws -> GethBlockchain {
        let blockchain = try GethBlockchain(network: network, storage: storage, transactionSigner: transactionSigner, transactionBuilder: transactionBuilder, address: address, logger: logger)

        return blockchain
    }

}

extension GethBlockchain {

    enum InitError: Error {
        case contextFailed
        case nodeFailed
    }

}
