import RxSwift
import HdWalletKit
import BigInt
import OpenSslKit
import Secp256k1Kit
import HsToolKit

public class Kit {
    public static let defaultGasLimit = 21_000

    private let disposeBag = DisposeBag()
    private let maxGasLimit = 2_000_000
    private let defaultMinAmount: BigUInt = 1

    private let lastBlockHeightSubject = PublishSubject<Int>()
    private let syncStateSubject = PublishSubject<SyncState>()
    private let accountStateSubject = PublishSubject<AccountState>()

    private let blockchain: IBlockchain
    private let transactionManager: TransactionManager
    private let transactionSyncManager: TransactionSyncManager
    private let internalTransactionSyncer: TransactionInternalTransactionSyncer
    private let transactionBuilder: TransactionBuilder
    private let transactionSigner: TransactionSigner
    private let ethSigner: EthSigner
    private let decorationManager: DecorationManager
    private let eip20Storage: Eip20Storage
    private let state: EthereumKitState

    public let address: Address

    public let networkType: NetworkType
    public let uniqueId: String
    public let etherscanService: EtherscanService

    public let logger: Logger


    init(blockchain: IBlockchain, transactionManager: TransactionManager, transactionSyncManager: TransactionSyncManager, internalTransactionSyncer: TransactionInternalTransactionSyncer,
         transactionBuilder: TransactionBuilder, transactionSigner: TransactionSigner, ethSigner: EthSigner, state: EthereumKitState = EthereumKitState(),
         address: Address, networkType: NetworkType, uniqueId: String, etherscanService: EtherscanService, decorationManager: DecorationManager, eip20Storage: Eip20Storage, logger: Logger) {
        self.blockchain = blockchain
        self.transactionManager = transactionManager
        self.transactionSyncManager = transactionSyncManager
        self.internalTransactionSyncer = internalTransactionSyncer
        self.transactionBuilder = transactionBuilder
        self.transactionSigner = transactionSigner
        self.ethSigner = ethSigner
        self.state = state
        self.address = address
        self.networkType = networkType
        self.uniqueId = uniqueId
        self.etherscanService = etherscanService
        self.decorationManager = decorationManager
        self.eip20Storage = eip20Storage
        self.logger = logger

        state.accountState = blockchain.accountState
        state.lastBlockHeight = blockchain.lastBlockHeight

        transactionManager.allTransactionsObservable
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] transactions in
                    self?.blockchain.syncAccountState()
                    self?.internalTransactionSyncer.sync(transactions: transactions)
                })
                .disposed(by: disposeBag)
    }

}

// Public API Extension

extension Kit {

    public var lastBlockHeight: Int? {
        state.lastBlockHeight
    }

    public var accountState: AccountState? {
        state.accountState
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

    public var syncStateObservable: Observable<SyncState> {
        syncStateSubject.asObservable()
    }

    public var transactionsSyncStateObservable: Observable<SyncState> {
        transactionSyncManager.stateObservable
    }

    public var accountStateObservable: Observable<AccountState> {
        accountStateSubject.asObservable()
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

    public func transactionsObservable(tags: [[String]]) -> Observable<[FullTransaction]> {
        transactionManager.transactionsObservable(tags: tags)
    }

    public func transactionsSingle(tags: [[String]], fromHash: Data? = nil, limit: Int? = nil) -> Single<[FullTransaction]> {
        transactionManager.transactionsSingle(tags: tags, fromHash: fromHash, limit: limit)
    }

    public func pendingTransactions(tags: [[String]]) -> [FullTransaction] {
        transactionManager.pendingTransactions(tags: tags)
    }

    public func transaction(hash: Data) -> FullTransaction? {
        transactionManager.transaction(hash: hash)
    }

    public func fullTransactions(byHashes hashes: [Data]) -> [FullTransaction] {
        transactionManager.transactions(byHashes: hashes)
    }

    public func sendSingle(address: Address, value: BigUInt, transactionInput: Data = Data(), gasPrice: Int, gasLimit: Int, nonce: Int? = nil) -> Single<FullTransaction> {
        var syncNonceSingle = blockchain.nonceSingle(defaultBlockParameter: .pending)

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
        sendSingle(address: transactionData.to, value: transactionData.value, transactionInput: transactionData.input, gasPrice: gasPrice, gasLimit: gasLimit, nonce: nonce)
    }

    public func signedTransaction(address: Address, value: BigUInt, transactionInput: Data = Data(), gasPrice: Int, gasLimit: Int, nonce: Int) throws -> Data {
        let rawTransaction = transactionBuilder.rawTransaction(gasPrice: gasPrice, gasLimit: gasLimit, to: address, value: value, data: transactionInput, nonce: nonce)
        let signature = try transactionSigner.signature(rawTransaction: rawTransaction)
        return transactionBuilder.encode(rawTransaction: rawTransaction, signature: signature)
    }

    public func signed(message: Data) throws -> Data {
        try ethSigner.sign(message: message)
    }

    public func parseTypedData(rawJson: Data) throws -> EIP712TypedData {
        try ethSigner.parseTypedData(rawJson: rawJson)
    }

    public func signTypedData(message: Data) throws -> Data {
        try ethSigner.signTypedData(message: message)
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

    public func add(transactionSyncer: ITransactionSyncer) {
        transactionSyncManager.add(syncer: transactionSyncer)
    }

    public func removeSyncer(byId id: String) {
        transactionSyncManager.removeSyncer(byId: id)
    }

    public func add(decorator: IDecorator) {
        decorationManager.add(decorator: decorator)
    }

    public func decorate(transactionData: TransactionData) -> ContractMethodDecoration? {
        decorationManager.decorateTransaction(transactionData: transactionData)
    }

    public func transferTransactionData(to: Address, value: BigUInt) -> TransactionData {
        transactionManager.etherTransferTransactionData(to: to, value: value)
    }

    public func add(transactionWatcher: ITransactionWatcher) {
        internalTransactionSyncer.add(watcher: transactionWatcher)
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

// Eip20Kit database helpers

extension Kit {

    public func balance(contractAddress: Address) -> BigUInt? {
        eip20Storage.balance(contractAddress: contractAddress)
    }

    public func save(balance: BigUInt, contractAddress: Address) {
        eip20Storage.save(balance: balance, contractAddress: contractAddress)
    }

}

extension Kit: IBlockchainDelegate {

    func onUpdate(lastBlockHeight: Int) {
        guard state.lastBlockHeight != lastBlockHeight else {
            return
        }

        state.lastBlockHeight = lastBlockHeight

        lastBlockHeightSubject.onNext(lastBlockHeight)
    }

    func onUpdate(accountState: AccountState) {
        guard state.accountState != accountState else {
            return
        }

        state.accountState = accountState
        accountStateSubject.onNext(accountState)
    }

    func onUpdate(syncState: SyncState) {
        syncStateSubject.onNext(syncState)
    }

}

extension Kit {

    public static func address(seed: Data, networkType: NetworkType = .ethMainNet) throws -> Address {
        let privKey = try privateKey(seed: seed, networkType: networkType)

        return ethereumAddress(privateKey: privKey)
    }

    public static func privateKey(seed: Data, networkType: NetworkType = .ethMainNet) throws -> HDPrivateKey {
        let wallet = hdWallet(seed: seed, networkType: networkType)
        return try wallet.privateKey(account: 0, index: 0, chain: .external)
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

    public static func instance(seed: Data, networkType: NetworkType, syncSource: SyncSource, etherscanApiKey: String, walletId: String, minLogLevel: Logger.Level = .error) throws -> Kit {
        let logger = Logger(minLogLevel: minLogLevel)
        let uniqueId = "\(walletId)-\(networkType)"

        let privKey = try privateKey(seed: seed, networkType: networkType)
        let address = ethereumAddress(privateKey: privKey)

        let networkManager = NetworkManager(logger: logger)

        let syncer: IRpcSyncer
        let reachabilityManager = ReachabilityManager()

        switch syncSource {
        case let .webSocket(url, auth):
            let socket = WebSocket(url: url, reachabilityManager: reachabilityManager, auth: auth, logger: logger)
            syncer = WebSocketRpcSyncer.instance(socket: socket, logger: logger)

        case let .http(url, blockTime, auth):
            let apiProvider = NodeApiProvider(networkManager: networkManager, url: url, blockTime: blockTime, auth: auth)
            syncer = ApiRpcSyncer(rpcApiProvider: apiProvider, reachabilityManager: reachabilityManager)
        }

        let transactionSigner = TransactionSigner(chainId: networkType.chainId, privateKey: privKey.raw)
        let transactionBuilder = TransactionBuilder(address: address)
        let ethSigner = EthSigner(privateKey: privKey.raw, cryptoUtils: CryptoUtils.shared)
        let etherscanService = EtherscanService(networkType: networkType, etherscanApiKey: etherscanApiKey, address: address, logger: logger)

        let storage: IApiStorage = try ApiStorage(databaseDirectoryUrl: dataDirectoryUrl(), databaseFileName: "api-\(uniqueId)")
        let blockchain = RpcBlockchain.instance(address: address, storage: storage, syncer: syncer, transactionSigner: transactionSigner, transactionBuilder: transactionBuilder, logger: logger)

        let transactionsProvider = EtherscanTransactionProvider(service: etherscanService)
        let transactionStorage: ITransactionStorage & ITransactionSyncerStateStorage = TransactionStorage(databaseDirectoryUrl: try dataDirectoryUrl(), databaseFileName: "transactions-\(uniqueId)")
        let notSyncedTransactionPool = NotSyncedTransactionPool(storage: transactionStorage)
        let notSyncedTransactionManager = NotSyncedTransactionManager(pool: notSyncedTransactionPool, storage: transactionStorage)

        let userInternalTransactionSyncer = UserInternalTransactionSyncer(provider: transactionsProvider, storage: transactionStorage)
        let transactionInternalTransactionSyncer = TransactionInternalTransactionSyncer(provider: transactionsProvider, storage: transactionStorage)
        let ethereumTransactionSyncer = EthereumTransactionSyncer(provider: transactionsProvider)
        let transactionSyncer = TransactionSyncer(blockchain: blockchain, storage: transactionStorage)
        let pendingTransactionSyncer = PendingTransactionSyncer(blockchain: blockchain, storage: transactionStorage)
        let transactionSyncManager = TransactionSyncManager(notSyncedTransactionManager: notSyncedTransactionManager)
        let decorationManager = DecorationManager(address: address)
        let tagGenerator = TagGenerator(address: address)
        let transactionManager = TransactionManager(address: address, storage: transactionStorage, transactionSyncManager: transactionSyncManager, decorationManager: decorationManager, tagGenerator: tagGenerator)

        transactionSyncManager.add(syncer: ethereumTransactionSyncer)
        transactionSyncManager.add(syncer: userInternalTransactionSyncer)
        transactionSyncManager.add(syncer: transactionInternalTransactionSyncer)
        transactionSyncManager.add(syncer: transactionSyncer)
        transactionSyncManager.add(syncer: pendingTransactionSyncer)

        let eip20Storage = Eip20Storage(databaseDirectoryUrl: try dataDirectoryUrl(), databaseFileName: "eip20-\(uniqueId)")

        let kit = Kit(
                blockchain: blockchain, transactionManager: transactionManager, transactionSyncManager: transactionSyncManager, internalTransactionSyncer: transactionInternalTransactionSyncer,
                transactionBuilder: transactionBuilder, transactionSigner: transactionSigner, ethSigner: ethSigner, address: address, networkType: networkType,
                uniqueId: uniqueId, etherscanService: etherscanService, decorationManager: decorationManager, eip20Storage: eip20Storage, logger: logger
        )

        blockchain.delegate = kit
        transactionSyncManager.set(ethereumKit: kit)
        transactionSyncer.listener = transactionSyncManager
        pendingTransactionSyncer.listener = transactionSyncManager
        userInternalTransactionSyncer.listener = transactionSyncManager
        transactionInternalTransactionSyncer.listener = transactionSyncManager

        decorationManager.add(decorator: ContractCallDecorator(address: address))

        return kit
    }

    private static func infuraDomain(networkType: NetworkType) -> String? {
        switch networkType {
        case .ethMainNet: return "mainnet.infura.io"
        case .ropsten: return "ropsten.infura.io"
        case .rinkeby: return "rinkeby.infura.io"
        case .kovan: return "kovan.infura.io"
        case .goerli: return "goerli.infura.io"
        default: return nil
        }
    }

    public static func infuraWebsocketSyncSource(networkType: NetworkType, projectId: String, projectSecret: String?) -> SyncSource? {
        guard let domain = infuraDomain(networkType: networkType), let url = URL(string: "wss://\(domain)/ws/v3/\(projectId)") else {
            return nil
        }

        return .webSocket(url: url, auth: projectSecret)
    }

    public static func infuraHttpSyncSource(networkType: NetworkType, projectId: String, projectSecret: String?) -> SyncSource? {
        guard let domain = infuraDomain(networkType: networkType), let url = URL(string: "https://\(domain)/v3/\(projectId)") else {
            return nil
        }

        return .http(url: url, blockTime: networkType.blockTime, auth: projectSecret)
    }

    public static func defaultBscWebsocketSyncSource() -> SyncSource? {
        guard let url = URL(string: "wss://bsc-ws-node.nariox.org:443") else {
            return nil
        }

        return .webSocket(url: url, auth: nil)
    }

    public static func defaultBscHttpSyncSource() -> SyncSource? {
        guard let url = URL(string: "https://bsc-dataseed.binance.org/v3/") else {
            return nil
        }

        return .http(url: url, blockTime: NetworkType.bscMainNet.blockTime, auth: nil)
    }

    private static func dataDirectoryUrl() throws -> URL {
        let fileManager = FileManager.default

        let url = try fileManager
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("ethereum-kit", isDirectory: true)

        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)

        return url
    }

    private static func hdWallet(seed: Data, networkType: NetworkType) -> HDWallet {
        let coinType: UInt32

        switch networkType {
        case .ropsten, .rinkeby, .kovan, .goerli: coinType = 1
        default: coinType = 60
        }

        return HDWallet(seed: seed, coinType: coinType, xPrivKey: 0, xPubKey: 0)
    }

    private static func ethereumAddress(privateKey: HDPrivateKey) -> Address {
        let publicKey = Data(Secp256k1Kit.Kit.createPublicKey(fromPrivateKeyData: privateKey.raw, compressed: false).dropFirst())

        return Address(raw: Data(CryptoUtils.shared.sha3(publicKey).suffix(20)))
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

}
