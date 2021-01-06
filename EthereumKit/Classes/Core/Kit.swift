import RxSwift
import HdWalletKit
import BigInt
import OpenSslKit
import Secp256k1Kit
import HsToolKit

public class Kit {
    public static let defaultGasLimit = 21_000

    private let maxGasLimit = 1_000_000
    private let defaultMinAmount: BigUInt = 1

    private let lastBlockBloomFilterSubject = PublishSubject<BloomFilter>()
    private let nonceSubject = PublishSubject<Int>()
    private let lastBlockHeightSubject = PublishSubject<Int>()
    private let syncStateSubject = PublishSubject<SyncState>()
    private let balanceSubject = PublishSubject<BigUInt>()

    private let blockchain: IBlockchain
    private let transactionManager: TransactionManager
    private let transactionSyncManager: TransactionSyncManager
    private let transactionBuilder: TransactionBuilder
    private let transactionSigner: TransactionSigner
    private let state: EthereumKitState

    public let address: Address

    public let networkType: NetworkType
    public let uniqueId: String
    public let etherscanApiProvider: EtherscanApiProvider

    public let logger: Logger


    init(blockchain: IBlockchain, transactionManager: TransactionManager, transactionSyncManager: TransactionSyncManager, transactionBuilder: TransactionBuilder, transactionSigner: TransactionSigner, state: EthereumKitState = EthereumKitState(), address: Address, networkType: NetworkType, uniqueId: String, etherscanApiProvider: EtherscanApiProvider, logger: Logger) {
        self.blockchain = blockchain
        self.transactionManager = transactionManager
        self.transactionSyncManager = transactionSyncManager
        self.transactionBuilder = transactionBuilder
        self.transactionSigner = transactionSigner
        self.state = state
        self.address = address
        self.networkType = networkType
        self.uniqueId = uniqueId
        self.etherscanApiProvider = etherscanApiProvider
        self.logger = logger

        state.balance = blockchain.balance
        state.lastBlockHeight = blockchain.lastBlockHeight
    }

}

// Public API Extension

extension Kit {

    public var lastBlockHeight: Int? {
        state.lastBlockHeight
    }

    public var balance: BigUInt? {
        state.balance
    }

    public var syncState: SyncState {
        blockchain.syncState
    }

    public var transactionsSyncState: SyncState {
        transactionSyncManager.state
    }

    public var receiveAddress: Address {
        address
    }

    public var lastBlockHeightObservable: Observable<Int> {
        lastBlockHeightSubject.asObservable()
    }

    public var nonceObservable: Observable<Int> {
        nonceSubject.asObservable()
    }

    public var lastBlockBloomFilterObservable: Observable<BloomFilter> {
        lastBlockBloomFilterSubject.asObservable()
    }

    public var syncStateObservable: Observable<SyncState> {
        syncStateSubject.asObservable()
    }

    public var transactionsSyncStateObservable: Observable<SyncState> {
        transactionSyncManager.stateObservable
    }

    public var balanceObservable: Observable<BigUInt> {
        balanceSubject.asObservable()
    }

    public var etherTransactionsObservable: Observable<[FullTransaction]> {
        transactionManager.etherTransactionsObservable
    }

    public var allTransactionsObservable: Observable<[FullTransaction]> {
        transactionManager.allTransactionsObservable
    }

    public func start() {
        blockchain.start()
    }

    public func stop() {
        blockchain.stop()
    }

    public func refresh() {
        blockchain.refresh()
    }

    public func etherTransactionsSingle(fromHash: Data? = nil, limit: Int? = nil) -> Single<[FullTransaction]> {
        transactionManager.etherTransactionsSingle(fromHash: fromHash, limit: limit)
    }

    public func transaction(hash: Data) -> FullTransaction? {
        transactionManager.transaction(hash: hash)
    }

    public func fullTransactions(fromHash: Data?) -> [FullTransaction] {
        transactionManager.transactions(fromHash: fromHash)
    }

    public func fullTransactions(byHashes hashes: [Data]) -> [FullTransaction] {
        transactionManager.transactions(byHashes: hashes)
    }

    public func sendSingle(address: Address, value: BigUInt, transactionInput: Data = Data(), gasPrice: Int, gasLimit: Int, nonce: Int? = nil) -> Single<FullTransaction> {
        var syncNonceSingle = blockchain.nonceSingle()

        if let nonce = nonce {
            syncNonceSingle = Single<Int>.just(nonce)
        }

        return syncNonceSingle.flatMap { [weak self] nonce in
            guard let kit = self else {
                return Single<FullTransaction>.error(SendError.nonceNotAvailable)
            }

            let rawTransaction = kit.transactionBuilder.rawTransaction(gasPrice: gasPrice, gasLimit: gasLimit, to: address, value: value, data: transactionInput, nonce: nonce)

            return kit.blockchain.sendSingle(rawTransaction: rawTransaction)
                    .do(onSuccess: { [weak self] transaction in
                        self?.transactionManager.handle(sentTransaction: transaction)
                    })
                    .map {
                        FullTransaction(transaction: $0)
                    }
        }
    }

    public func sendSingle(transactionData: TransactionData, gasPrice: Int, gasLimit: Int, nonce: Int? = nil) -> Single<FullTransaction> {
        sendSingle(transactionData: transactionData, gasPrice: gasPrice, gasLimit: gasLimit, nonce: nonce)
    }

    public func signedTransaction(address: Address, value: BigUInt, transactionInput: Data = Data(), gasPrice: Int, gasLimit: Int, nonce: Int) throws -> Data {
        let rawTransaction = transactionBuilder.rawTransaction(gasPrice: gasPrice, gasLimit: gasLimit, to: address, value: value, data: transactionInput, nonce: nonce)
        let signature = try transactionSigner.signature(rawTransaction: rawTransaction)
        return transactionBuilder.encode(rawTransaction: rawTransaction, signature: signature)
    }

    public var debugInfo: String {
        var lines = [String]()

        lines.append("ADDRESS: \(address.hex)")

        return lines.joined(separator: "\n")
    }

    public func getStorageAt(contractAddress: Address, positionData: Data, defaultBlockParameter: DefaultBlockParameter = .latest) -> Single<Data> {
        blockchain.getStorageAt(contractAddress: contractAddress, positionData: positionData, defaultBlockParameter: defaultBlockParameter)
    }

    public func call(contractAddress: Address, data: Data, defaultBlockParameter: DefaultBlockParameter = .latest) -> Single<Data> {
        blockchain.call(contractAddress: contractAddress, data: data, defaultBlockParameter: defaultBlockParameter)
    }

    public func estimateGas(to: Address?, amount: BigUInt, gasPrice: Int?) -> Single<Int> {
        // without address - provide default gas limit
        guard let to = to else {
            return Single.just(Kit.defaultGasLimit)
        }

        // if amount is 0 - set default minimum amount
        let resolvedAmount: BigUInt = amount == 0 ? defaultMinAmount : amount

        return blockchain.estimateGas(to: to, amount: resolvedAmount, gasLimit: maxGasLimit, gasPrice: gasPrice, data: nil)
    }

    public func estimateGas(to: Address?, amount: BigUInt?, gasPrice: Int?, data: Data?) -> Single<Int> {
        blockchain.estimateGas(to: to, amount: amount, gasLimit: maxGasLimit, gasPrice: gasPrice, data: data)
    }

    public func estimateGas(transactionData: TransactionData, gasPrice: Int?) -> Single<Int> {
        estimateGas(to: transactionData.to, amount: transactionData.value, gasPrice: gasPrice, data: transactionData.input)
    }

    public func add(syncer: ITransactionSyncer) {
        transactionSyncManager.add(syncer: syncer)
    }
    
    public func removeSyncer(byId id: String) {
        transactionSyncManager.removeSyncer(byId: id)
    }

    public func statusInfo() -> [(String, Any)] {
        [
            ("Last Block Height", "\(state.lastBlockHeight.map { "\($0)" } ?? "N/A")"),
            ("Sync State", blockchain.syncState.description),
            ("Blockchain Source", blockchain.source),
            ("Transactions Source", "Infura.io, Etherscan.io")
        ]
    }

}


extension Kit: IBlockchainDelegate {

    func onUpdate(lastBlockBloomFilter: BloomFilter) {
        lastBlockBloomFilterSubject.onNext(lastBlockBloomFilter)
    }

    func onUpdate(lastBlockHeight: Int) {
        guard state.lastBlockHeight != lastBlockHeight else {
            return
        }

        state.lastBlockHeight = lastBlockHeight

        lastBlockHeightSubject.onNext(lastBlockHeight)
    }

    func onUpdate(balance: BigUInt) {
        guard state.balance != balance else {
            return
        }

        state.balance = balance
        balanceSubject.onNext(balance)
    }

    func onUpdate(syncState: SyncState) {
        syncStateSubject.onNext(syncState)
    }

    func onUpdate(nonce: Int) {
        guard state.nonce != nonce else {
            return
        }

        state.nonce = nonce
        nonceSubject.onNext(nonce)
    }

}

extension Kit {

    public static func instance(privateKey: Data, syncMode: SyncMode, networkType: NetworkType = .mainNet, syncSource: SyncSource, etherscanApiKey: String, walletId: String, minLogLevel: Logger.Level = .error) throws -> Kit {
        let logger = Logger(minLogLevel: minLogLevel)

        let uniqueId = "\(walletId)-\(networkType)"

        let publicKey = Data(Secp256k1Kit.Kit.createPublicKey(fromPrivateKeyData: privateKey, compressed: false).dropFirst())
        let address = Address(raw: Data(CryptoUtils.shared.sha3(publicKey).suffix(20)))

        let network: INetwork = networkType.network
        let transactionSigner = TransactionSigner(network: network, privateKey: privateKey)
        let transactionBuilder = TransactionBuilder(address: address)
        let networkManager = NetworkManager(logger: logger)

        let etherscanApiProvider = EtherscanApiProvider(networkManager: networkManager, network: network, etherscanApiKey: etherscanApiKey, address: address)
        let transactionsProvider = EtherscanTransactionProvider(provider: etherscanApiProvider)

        let infuraDomain: String
        switch networkType {
        case .ropsten: infuraDomain = "ropsten.infura.io"
        case .kovan: infuraDomain = "kovan.infura.io"
        case .mainNet: infuraDomain = "mainnet.infura.io"
        }

        let syncer: IRpcSyncer
        let reachabilityManager = ReachabilityManager()

        switch syncSource {
        case let .infuraWebSocket(id, secret):
            let socket = InfuraWebSocket(domain: infuraDomain, projectId: id, projectSecret: secret, reachabilityManager: reachabilityManager, logger: logger)
            syncer = WebSocketRpcSyncer.instance(address: address, socket: socket, logger: logger)
        case let .infura(id, secret):
            syncer = ApiRpcSyncer(address: address, rpcApiProvider: InfuraApiProvider(networkManager: networkManager, domain: infuraDomain, id: id, secret: secret), reachabilityManager: reachabilityManager)
//        case .incubed:
//            syncer = ApiRpcSyncer(address: address, rpcApiProvider: IncubedRpcApiProvider(logger: logger), reachabilityManager: ReachabilityManager())
        }

        var blockchain: IBlockchain

        switch syncMode {
        case .api:
            let storage: IApiStorage = try ApiStorage(databaseDirectoryUrl: dataDirectoryUrl(), databaseFileName: "api-\(uniqueId)")
            blockchain = RpcBlockchain.instance(address: address, storage: storage, syncer: syncer, transactionSigner: transactionSigner, transactionBuilder: transactionBuilder, logger: logger)

        case .spv(let nodePrivateKey):
            let storage: ISpvStorage = try SpvStorage(databaseDirectoryUrl: dataDirectoryUrl(), databaseFileName: "spv-\(uniqueId)")

            let nodePublicKey = Data(Secp256k1Kit.Kit.createPublicKey(fromPrivateKeyData: nodePrivateKey, compressed: false).dropFirst())
            let nodeKey = ECKey(privateKey: nodePrivateKey, publicKeyPoint: ECPoint(nodeId: nodePublicKey))

            let discoveryStorage = try DiscoveryStorage(databaseDirectoryUrl: dataDirectoryUrl(), databaseFileName: "dcvr-\(uniqueId)")

            let packetSerializer = PacketSerializer(serializers: [
                PingPackageSerializer(),
                PongPackageSerializer(),
                FindNodePackageSerializer(),
            ], privateKey: nodeKey.privateKey)

            let packetParser = PacketParser(parsers: [
                0x01: PingPackageParser(),
                0x02: PongPackageParser(),
                0x04: NeighborsPackageParser(),
            ])

            let udpFactory = UdpFactory(packetSerializer: packetSerializer)
            let nodeFactory = NodeFactory()

            let nodeDiscovery = NodeDiscovery(ecKey: nodeKey, factory: udpFactory, discoveryStorage: discoveryStorage, nodeParser: NodeParser(), packetParser: packetParser)
            let nodeManager = NodeManager(storage: discoveryStorage, nodeDiscovery: nodeDiscovery, nodeFactory: nodeFactory, logger: logger)
            nodeDiscovery.nodeManager = nodeManager

            blockchain = SpvBlockchain.instance(storage: storage, nodeManager: nodeManager, transactionSigner: transactionSigner, transactionBuilder: transactionBuilder, network: network, address: address, nodeKey: nodeKey, logger: logger)
        case .geth:
            fatalError("Geth is not supported")
//            let directoryUrl = try dataDirectoryUrl()
//            let storage: IApiStorage = ApiStorage(databaseDirectoryUrl: directoryUrl, databaseFileName: "geth-\(uniqueId)")
//            let nodeDirectory = directoryUrl.appendingPathComponent("node-\(uniqueId)", isDirectory: true)
//            blockchain = try GethBlockchain.instance(nodeDirectory: nodeDirectory, network: network, storage: storage, transactionSigner: transactionSigner, transactionBuilder: transactionBuilder, address: address, logger: logger)
        }

        let transactionStorage: ITransactionStorage & ITransactionSyncerStateStorage = TransactionStorage(databaseDirectoryUrl: try dataDirectoryUrl(), databaseFileName: "transactions-\(uniqueId)")
        let notSyncedTransactionPool = NotSyncedTransactionPool(storage: transactionStorage)
        let notSyncedTransactionManager = NotSyncedTransactionManager(pool: notSyncedTransactionPool, storage: transactionStorage)

        let internalTransactionSyncer = InternalTransactionSyncer(provider: transactionsProvider, storage: transactionStorage)
        let ethereumTransactionSyncer = EthereumTransactionSyncer(provider: transactionsProvider)
        let transactionSyncer = TransactionSyncer(blockchain: blockchain, storage: transactionStorage)
        let outgoingPendingTransactionSyncer = OutgoingPendingTransactionSyncer(blockchain: blockchain, storage: transactionStorage)
        let transactionSyncManager = TransactionSyncManager(notSyncedTransactionManager: notSyncedTransactionManager)
        let transactionManager = TransactionManager(address: address, storage: transactionStorage, transactionSyncManager: transactionSyncManager)

        transactionSyncManager.add(syncer: ethereumTransactionSyncer)
        transactionSyncManager.add(syncer: internalTransactionSyncer)
        transactionSyncManager.add(syncer: transactionSyncer)
        transactionSyncManager.add(syncer: outgoingPendingTransactionSyncer)

        let ethereumKit = Kit(blockchain: blockchain, transactionManager: transactionManager, transactionSyncManager: transactionSyncManager, transactionBuilder: transactionBuilder, transactionSigner: transactionSigner, address: address, networkType: networkType, uniqueId: uniqueId, etherscanApiProvider: etherscanApiProvider, logger: logger)

        blockchain.delegate = ethereumKit
        transactionSyncManager.set(ethereumKit: ethereumKit)
        transactionSyncer.listener = transactionSyncManager
        outgoingPendingTransactionSyncer.listener = transactionSyncManager

        return ethereumKit
    }

    public static func instance(words: [String], syncMode wordsSyncMode: WordsSyncMode, networkType: NetworkType = .mainNet, rpcApi: SyncSource, etherscanApiKey: String, walletId: String, minLogLevel: Logger.Level = .error) throws -> Kit {
        let coinType: UInt32 = networkType == .mainNet ? 60 : 1

        let hdWallet = HDWallet(seed: Mnemonic.seed(mnemonic: words), coinType: coinType, xPrivKey: 0, xPubKey: 0)
        let privateKey = try hdWallet.privateKey(account: 0, index: 0, chain: .external).raw

        let syncMode: SyncMode

        switch wordsSyncMode {
        case .api: syncMode = .api
        case .spv: syncMode = .spv(nodePrivateKey: try hdWallet.privateKey(account: 100, index: 100, chain: .external).raw)
        case .geth: syncMode = .geth
        }

        return try instance(privateKey: privateKey, syncMode: syncMode, networkType: networkType, syncSource: rpcApi, etherscanApiKey: etherscanApiKey, walletId: walletId, minLogLevel: minLogLevel)
    }

    public static func clear(exceptFor excludedFiles: [String]) throws {
        let fileManager = FileManager.default
        let fileUrls = try fileManager.contentsOfDirectory(at: dataDirectoryUrl(), includingPropertiesForKeys: nil)

        for filename in fileUrls {
            if !excludedFiles.contains(where: { filename.lastPathComponent.contains($0) }) {
                try fileManager.removeItem(at: filename)
            }
        }
    }

    private static func dataDirectoryUrl() throws -> URL {
        let fileManager = FileManager.default

        let url = try fileManager
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("ethereum-kit", isDirectory: true)

        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)

        return url
    }

}

extension Kit {

    public enum SyncError: Error {
        case notStarted
        case noNetworkConnection
    }

    public enum SendError: Error {
        case nonceNotAvailable
        case noAccountState
    }

    public enum EstimatedLimitError: Error {
        case insufficientBalance

        var causes: [String] {
            [
                "execution reverted",
                "insufficient funds for transfer",
                "gas required exceeds"
            ]
        }
    }

}
