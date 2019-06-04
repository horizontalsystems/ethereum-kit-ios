//import RxSwift
//import BigInt
//import Geth
//
//class GethBlockchain: NSObject {
//    private let disposeBag = DisposeBag()
//
//    weak var delegate: IBlockchainDelegate?
//
//    private let network: INetwork
//    private let storage: IApiStorage
//    private let transactionSigner: TransactionSigner
//    private let transactionBuilder: TransactionBuilder
//    private let logger: Logger?
//
//    private let account: GethAddress?
//
//    private let context: GethContext
//    private let node: GethNode
//
//    private let lastBlockHeightSubject = PublishSubject<Int>()
//
//    private(set) var syncState: EthereumKit.SyncState = .syncing(progress: nil) {
//        didSet {
//            if syncState != oldValue {
//                delegate?.onUpdate(syncState: syncState)
//            }
//        }
//    }
//
//    private init(node: GethNode, network: INetwork, storage: IApiStorage, transactionSigner: TransactionSigner, transactionBuilder: TransactionBuilder, account: GethAddress?, logger: Logger? = nil) throws {
//        self.node = node
//        self.network = network
//        self.storage = storage
//        self.transactionSigner = transactionSigner
//        self.transactionBuilder = transactionBuilder
//        self.account = account
//        self.logger = logger
//
//        guard let context = GethContext() else {
//            throw InitError.contextFailed
//        }
//
//        self.context = context
//
//        super.init()
//
//        lastBlockHeightSubject.throttle(.seconds(1), scheduler: ConcurrentDispatchQueueScheduler(qos: .background))
//                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
//                .subscribe(onNext: { [weak self] in
//                    self?.update(lastBlockHeight: $0)
//                })
//                .disposed(by: disposeBag)
//    }
//
//    private func update(lastBlockHeight: Int) {
//        storage.save(lastBlockHeight: lastBlockHeight)
//        delegate?.onUpdate(lastBlockHeight: lastBlockHeight)
//
//        do {
//            let syncProgress = try node.getEthereumClient().syncProgress(context)
//
//            let startingBlock = Double(syncProgress.getStartingBlock())
//            let highestBlock = Double(syncProgress.getHighestBlock())
//            let currentBlock = Double(syncProgress.getCurrentBlock())
//
//            let progress = (currentBlock - startingBlock) / (highestBlock - startingBlock)
//
//            syncState = .syncing(progress: progress)
//        } catch {
//            let peersCount = node.getPeersInfo()?.size() ?? 0
//
//            if peersCount == 0 {
//                syncState = .syncing(progress: nil)
//            } else {
//                syncState = .synced
//
//                syncAccountState()
//            }
//        }
//    }
//
//    private func syncAccountState() {
//        do {
//            let gethBalance = try node.getEthereumClient().getBalanceAt(context, account: account, number: -1)
//
//            guard let balance = BigUInt(gethBalance.string()) else {
//                return
//            }
//
//            update(balance: balance)
//        } catch {
//            logger?.error("Could not fetch account state: \(error)")
//        }
//    }
//
//    private func update(balance: BigUInt) {
//        storage.save(balance: balance)
//        delegate?.onUpdate(balance: balance)
//    }
//
//    private func send(rawTransaction: RawTransaction) throws -> Transaction {
//        var nonce: Int64 = 0
//        try node.getEthereumClient().getNonceAt(context, account: account, number: -1, nonce: &nonce)
//
//        logger?.info("NONCE: \(nonce)")
//
//        let toAccount = GethAddress(fromBytes: rawTransaction.to)
//
//        let amount = GethBigInt(0)
//        amount?.setString(rawTransaction.value.description, base: 10)
//
//        let gethTransaction = GethTransaction(
//                nonce,
//                to: toAccount,
//                amount: amount,
//                gasLimit: Int64(rawTransaction.gasLimit),
//                gasPrice: GethBigInt(Int64(rawTransaction.gasPrice)),
//                data: rawTransaction.data
//        )
//
//        let signature = try transactionSigner.sign(rawTransaction: rawTransaction, nonce: Int(nonce))
//        let signedTransaction = try gethTransaction?.withSignature(signature, chainID: GethBigInt(Int64(network.chainId)))
//
//        try node.getEthereumClient().sendTransaction(context, tx: signedTransaction)
//
//        return transactionBuilder.transaction(rawTransaction: rawTransaction, nonce: Int(nonce), signature: transactionSigner.signature(from: signature))
//    }
//
//    private func call(contractAddress: Data, data: Data, blockHeight: Int?) throws -> Data {
//        logger?.verbose("Calling \(contractAddress.toHexString()), blockHeight: \(blockHeight ?? -1)")
//
//        let message = GethCallMsg()
//        message?.setTo(GethAddress(fromBytes: contractAddress))
//        message?.setData(data)
//
//        let data = try node.getEthereumClient().callContract(context, msg: message, number: Int64(blockHeight ?? -1))
//
//        logger?.verbose("Call result: \(data.toHexString())")
//
//        return data
//    }
//
//    private func getLogs(address: Data?, topics: [Any?], fromBlock: Int, toBlock: Int, pullTimestamps: Bool) throws -> [EthereumLog] {
//        logger?.verbose("Get logs: \(address?.toHexString() ?? "nil"), \(fromBlock) -- \(toBlock), topics: \(topics.count)")
//
//        let addresses = GethNewAddressesEmpty()
//        addresses?.append(GethAddress(fromBytes: address))
//
//        let gethTopics = GethNewTopics(topics.count)
//        for (index, topic) in topics.enumerated() {
//            if let array = topic as? [Data?] {
//                let hashes = GethNewHashes(array.count)
//
//                for (index, topic) in array.enumerated() {
//                    if let data = topic {
//                        try hashes?.set(index, hash: GethHash(fromBytes: data))
//                    }
//                }
//
//                try gethTopics?.set(index, topics: hashes)
//            } else if let data = topic as? Data {
//                let hashes = GethNewHashesEmpty()
//                hashes?.append(GethHash(fromBytes: data))
//                try gethTopics?.set(index, topics: hashes)
//            }
//        }
//
//        let query = GethFilterQuery()
//        query?.setAddresses(addresses)
//        query?.setFromBlock(GethBigInt(Int64(fromBlock)))
//        query?.setToBlock(GethBigInt(Int64(toBlock)))
//        query?.setTopics(gethTopics)
//
//        let ethLogs = try node.getEthereumClient().filterLogs(context, query: query)
//
//        logger?.verbose("Eth logs result: \(ethLogs.size())")
//
//        var logs = [EthereumLog]()
//
//        for i in 0..<ethLogs.size() {
//            if let ethLog = try? ethLogs.get(i), let log = log(fromGethLog: ethLog) {
//                logs.append(log)
//            }
//        }
//
//        logger?.verbose("Logs result: \(ethLogs.size())")
//
//        return logs
//    }
//
//    private func log(fromGethLog gethLog: GethLog) -> EthereumLog? {
//        guard let address = gethLog.getAddress()?.getBytes() else {
//            return nil
//        }
//
//        guard let blockHash = gethLog.getBlockHash()?.getBytes() else {
//            return nil
//        }
//
//        guard let data = gethLog.getData() else {
//            return nil
//        }
//
//        guard let gethTopics = gethLog.getTopics() else {
//            return nil
//        }
//
//        guard let transactionHash = gethLog.getTxHash()?.getBytes() else {
//            return nil
//        }
//
//        var topics = [Data]()
//
//        for i in 0..<gethTopics.size() {
//            guard let hash = try? gethTopics.get(i), let bytes = hash.getBytes() else {
//                return nil
//            }
//
//            topics.append(bytes)
//        }
//
//        return EthereumLog(
//                address: address,
//                blockHash: blockHash,
//                blockNumber: Int(gethLog.getBlockNumber()),
//                data: data,
//                logIndex: gethLog.getIndex(),
//                removed: false,
//                topics: topics,
//                transactionHash: transactionHash,
//                transactionIndex: gethLog.getTxIndex()
//        )
//    }
//
//}
//
//extension GethBlockchain: IBlockchain {
//
//    func start() {
//        do {
//            try node.start()
//            logger?.verbose("GethBlockchain: started")
//        } catch {
//            logger?.error("GethBlockchain: failed to start node: \(error)")
//        }
//
//        do {
//            try node.getEthereumClient().subscribeNewHead(context, handler: self, buffer: 16)
//            logger?.verbose("GethBlockchain: subscribed to new headers")
//        } catch {
//            logger?.error("GethBlockchain: failed to subscribe to new headers: \(error)")
//        }
//    }
//
//    func stop() {
//        do {
//            try node.stop()
//            logger?.verbose("GethBlockchain: stopped")
//        } catch {
//            logger?.error("GethBlockchain: failed to stop node: \(error)")
//        }
//    }
//
//    func refresh() {
//    }
//
//    var lastBlockHeight: Int? {
//        return storage.lastBlockHeight
//    }
//
//    var balance: BigUInt? {
//        return storage.balance
//    }
//
//    func sendSingle(rawTransaction: RawTransaction) -> Single<Transaction> {
//        return Single.create { [unowned self] observer in
//            do {
//                let transaction = try self.send(rawTransaction: rawTransaction)
//
//                observer(.success(transaction))
//            } catch {
//                self.logger?.error("Send error: \(error)")
//
//                observer(.error(error))
//            }
//
//            return Disposables.create()
//        }
//    }
//
//    func getLogsSingle(address: Data?, topics: [Any?], fromBlock: Int, toBlock: Int, pullTimestamps: Bool) -> Single<[EthereumLog]> {
//        return Single.create { [unowned self] observer in
//            do {
//                let logs = try self.getLogs(address: address, topics: topics, fromBlock: fromBlock, toBlock: toBlock, pullTimestamps: pullTimestamps)
//
//                observer(.success(logs))
//            } catch {
//                self.logger?.error("Logs error: \(error)")
//
//                observer(.error(error))
//            }
//
//            return Disposables.create()
//        }
//    }
//
//    func getStorageAt(contractAddress: Data, positionData: Data, blockHeight: Int) -> Single<Data> {
//        fatalError("Not implemented yet")
//    }
//
//    func call(contractAddress: Data, data: Data, blockHeight: Int?) -> Single<Data> {
//        return Single.create { [unowned self] observer in
//            do {
//                let data: Data = try self.call(contractAddress: contractAddress, data: data, blockHeight: blockHeight)
//
//                observer(.success(data))
//            } catch {
//                self.logger?.error("Call error: \(error.localizedDescription)")
//
//                observer(.error(error))
//            }
//
//            return Disposables.create()
//        }
//    }
//
//}
//
//extension GethBlockchain: GethNewHeadHandlerProtocol {
//
//    public func onNewHead(_ header: GethHeader?) {
//        guard let blockNumber = header?.getNumber() else {
//            return
//        }
//
//        lastBlockHeightSubject.onNext(Int(blockNumber))
//    }
//
//    public func onError(_ failure: String?) {
//        print("NEW HEAD ERROR: \(failure ?? "nil")")
//    }
//
//}
//
//extension GethBlockchain {
//
//    static func instance(nodeDirectory: URL, network: INetwork, storage: IApiStorage, transactionSigner: TransactionSigner, transactionBuilder: TransactionBuilder, address: Data, logger: Logger? = nil) throws -> GethBlockchain {
//        let account = GethAddress(fromBytes: address)
//
//        let config = GethNewNodeConfig()
//        config?.ethereumGenesis = network is Ropsten ? GethTestnetGenesis() : GethMainnetGenesis()
//        config?.ethereumNetworkID = Int64(network.chainId)
//        config?.bootstrapNodes = GethFoundationBootnodes()
//        config?.ethereumEnabled = true
//        config?.maxPeers = 25
//        config?.whisperEnabled = false
//
//        var error: NSError?
//        guard let node = GethNewNode(nodeDirectory.path, config, &error) else {
//            throw InitError.nodeFailed
//        }
//
//        let blockchain = try GethBlockchain(node: node, network: network, storage: storage, transactionSigner: transactionSigner, transactionBuilder: transactionBuilder, account: account, logger: logger)
//
//        return blockchain
//    }
//
//}
//
//extension GethBlockchain {
//
//    enum InitError: Error {
//        case contextFailed
//        case nodeFailed
//    }
//
//}
