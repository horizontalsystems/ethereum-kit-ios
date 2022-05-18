import Foundation
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
    private let decorationManager: DecorationManager
    private let eip20Storage: Eip20Storage
    private let state: EthereumKitState

    public let address: Address

    public let chain: Chain
    public let uniqueId: String
    public let transactionProvider: ITransactionProvider

    public let logger: Logger


    init(blockchain: IBlockchain, transactionManager: TransactionManager, transactionSyncManager: TransactionSyncManager,
         state: EthereumKitState = EthereumKitState(),
         address: Address, chain: Chain, uniqueId: String, transactionProvider: ITransactionProvider, decorationManager: DecorationManager, eip20Storage: Eip20Storage, logger: Logger) {
        self.blockchain = blockchain
        self.transactionManager = transactionManager
        self.transactionSyncManager = transactionSyncManager
        self.state = state
        self.address = address
        self.chain = chain
        self.uniqueId = uniqueId
        self.transactionProvider = transactionProvider
        self.decorationManager = decorationManager
        self.eip20Storage = eip20Storage
        self.logger = logger

        state.accountState = blockchain.accountState
        state.lastBlockHeight = blockchain.lastBlockHeight

        transactionManager.fullTransactionsObservable
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] transactions in
                    self?.blockchain.syncAccountState()
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
        transactionManager.fullTransactionsObservable
    }

    public func start() {
        blockchain.start()
        transactionSyncManager.sync()
    }

    public func stop() {
        blockchain.stop()
    }

    public func refresh() {
        blockchain.refresh()
        transactionSyncManager.sync()
    }

    public func transactionSingle(hash: Data) -> Single<FullTransaction> {
        transactionManager.fullTransactionSingle(hash: hash)
    }

    public func transactionsObservable(tags: [[String]]) -> Observable<[FullTransaction]> {
        transactionManager.fullTransactionsObservable(tags: tags)
    }

    public func transactionsSingle(tags: [[String]], fromHash: Data? = nil, limit: Int? = nil) -> Single<[FullTransaction]> {
        transactionManager.fullTransactionsSingle(tags: tags, fromHash: fromHash, limit: limit)
    }

    public func pendingTransactions(tags: [[String]]) -> [FullTransaction] {
        transactionManager.pendingFullTransactions(tags: tags)
    }

    public func transaction(hash: Data) -> FullTransaction? {
        transactionManager.fullTransaction(hash: hash)
    }

    public func fullTransactions(byHashes hashes: [Data]) -> [FullTransaction] {
        transactionManager.fullTransactions(byHashes: hashes)
    }

    public func rawTransaction(transactionData: TransactionData, gasPrice: GasPrice, gasLimit: Int, nonce: Int? = nil) -> Single<RawTransaction> {
        rawTransaction(address: transactionData.to, value: transactionData.value, transactionInput: transactionData.input, gasPrice: gasPrice, gasLimit: gasLimit, nonce: nonce)
    }

    public func rawTransaction(address: Address, value: BigUInt, transactionInput: Data = Data(), gasPrice: GasPrice, gasLimit: Int, nonce: Int? = nil) -> Single<RawTransaction> {
        var syncNonceSingle = blockchain.nonceSingle(defaultBlockParameter: .pending)

        if let nonce = nonce {
            syncNonceSingle = Single<Int>.just(nonce)
        }

        return syncNonceSingle.map { nonce in
            RawTransaction(gasPrice: gasPrice, gasLimit: gasLimit, to: address, value: value, data: transactionInput, nonce: nonce)
        }
    }

    public func sendSingle(rawTransaction: RawTransaction, signature: Signature) -> Single<FullTransaction> {
        blockchain.sendSingle(rawTransaction: rawTransaction, signature: signature)
                .map { [unowned self] transaction in
                    let fullTransactions = transactionManager.handle(transactions: [transaction])
                    return fullTransactions[0]
                }
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

    public func estimateGas(to: Address?, amount: BigUInt, gasPrice: GasPrice) -> Single<Int> {
        // without address - provide default gas limit
        guard let to = to else {
            return Single.just(Kit.defaultGasLimit)
        }

        // if amount is 0 - set default minimum amount
        let resolvedAmount: BigUInt = amount == 0 ? defaultMinAmount : amount

        return blockchain.estimateGas(to: to, amount: resolvedAmount, gasLimit: maxGasLimit, gasPrice: gasPrice, data: nil)
    }

    public func estimateGas(to: Address?, amount: BigUInt?, gasPrice: GasPrice, data: Data?) -> Single<Int> {
        blockchain.estimateGas(to: to, amount: amount, gasLimit: maxGasLimit, gasPrice: gasPrice, data: data)
    }

    public func estimateGas(transactionData: TransactionData, gasPrice: GasPrice) -> Single<Int> {
        estimateGas(to: transactionData.to, amount: transactionData.value, gasPrice: gasPrice, data: transactionData.input)
    }

    func rpcSingle<T>(rpcRequest: JsonRpc<T>) -> Single<T> {
        blockchain.rpcSingle(rpcRequest: rpcRequest)
    }

    public func add(transactionSyncer: ITransactionSyncer) {
        transactionSyncManager.add(syncer: transactionSyncer)
    }

    public func add(methodDecorator: IMethodDecorator) {
        decorationManager.add(methodDecorator: methodDecorator)
    }

    public func add(eventDecorator: IEventDecorator) {
        decorationManager.add(eventDecorator: eventDecorator)
    }

    public func add(transactionDecorator: ITransactionDecorator) {
        decorationManager.add(transactionDecorator: transactionDecorator)
    }

    public func decorate(transactionData: TransactionData) -> TransactionDecoration? {
        decorationManager.decorateTransaction(from: address, transactionData: transactionData)
    }

    public func transferTransactionData(to: Address, value: BigUInt) -> TransactionData {
        transactionManager.etherTransferTransactionData(to: to, value: value)
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

    public func events() -> [Event] {
        eip20Storage.events()
    }

    public func events(hashes: [Data]) -> [Event] {
        eip20Storage.events(hashes: hashes)
    }

    public func save(events: [Event]) {
        eip20Storage.save(events: events)
    }

}

extension Kit: IBlockchainDelegate {

    func onUpdate(lastBlockHeight: Int) {
        guard state.lastBlockHeight != lastBlockHeight else {
            return
        }

        state.lastBlockHeight = lastBlockHeight

        lastBlockHeightSubject.onNext(lastBlockHeight)
        transactionSyncManager.sync()
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

    public static func clear(exceptFor excludedFiles: [String]) throws {
        let fileManager = FileManager.default
        let fileUrls = try fileManager.contentsOfDirectory(at: dataDirectoryUrl(), includingPropertiesForKeys: nil)

        for filename in fileUrls {
            if !excludedFiles.contains(where: { filename.lastPathComponent.contains($0) }) {
                try fileManager.removeItem(at: filename)
            }
        }
    }

    public static func instance(address: Address, chain: Chain, rpcSource: RpcSource, transactionSource: TransactionSource, walletId: String, minLogLevel: Logger.Level = .error) throws -> Kit {
        let logger = Logger(minLogLevel: minLogLevel)
        let uniqueId = "\(walletId)-\(chain.id)"

        let networkManager = NetworkManager(logger: logger)

        let syncer: IRpcSyncer
        let reachabilityManager = ReachabilityManager()

        switch rpcSource {
        case let .http(urls, auth):
            let apiProvider = NodeApiProvider(networkManager: networkManager, urls: urls, auth: auth)
            syncer = ApiRpcSyncer(rpcApiProvider: apiProvider, reachabilityManager: reachabilityManager, syncInterval: chain.syncInterval)
        case let .webSocket(url, auth):
            let socket = WebSocket(url: url, reachabilityManager: reachabilityManager, auth: auth, logger: logger)
            syncer = WebSocketRpcSyncer.instance(socket: socket, logger: logger)
        }

        let transactionBuilder = TransactionBuilder(chain: chain, address: address)
        let transactionProvider: ITransactionProvider = transactionProvider(transactionSource: transactionSource, address: address, logger: logger)

        let storage: IApiStorage = try ApiStorage(databaseDirectoryUrl: dataDirectoryUrl(), databaseFileName: "api-\(uniqueId)")
        let blockchain = RpcBlockchain.instance(address: address, storage: storage, syncer: syncer, transactionBuilder: transactionBuilder, logger: logger)

        let transactionStorage: ITransactionStorage = TransactionStorage(databaseDirectoryUrl: try dataDirectoryUrl(), databaseFileName: "transactions-\(uniqueId)")

        let ethereumTransactionSyncer = EthereumTransactionSyncer(provider: transactionProvider)
        let internalTransactionSyncer = InternalTransactionSyncer(provider: transactionProvider, storage: transactionStorage)
        let decorationManager = DecorationManager(userAddress: address, storage: transactionStorage)
        let transactionManager = TransactionManager(storage: transactionStorage, decorationManager: decorationManager, blockchain: blockchain, transactionProvider: transactionProvider)
        let transactionSyncManager = TransactionSyncManager(transactionManager: transactionManager)

        transactionSyncManager.add(syncer: ethereumTransactionSyncer)
        transactionSyncManager.add(syncer: internalTransactionSyncer)

        let eip20Storage = Eip20Storage(databaseDirectoryUrl: try dataDirectoryUrl(), databaseFileName: "eip20-\(uniqueId)")

        let kit = Kit(
                blockchain: blockchain, transactionManager: transactionManager, transactionSyncManager: transactionSyncManager,
                address: address, chain: chain,
                uniqueId: uniqueId, transactionProvider: transactionProvider, decorationManager: decorationManager, eip20Storage: eip20Storage, logger: logger
        )

        blockchain.delegate = kit

        decorationManager.add(transactionDecorator: EthereumDecorator(address: address))

        return kit
    }

    private static func transactionProvider(transactionSource: TransactionSource, address: Address, logger: Logger) -> ITransactionProvider {
        switch transactionSource.type {
        case .etherscan(let apiBaseUrl, _, let apiKey):
            return EtherscanTransactionProvider(baseUrl: apiBaseUrl, apiKey: apiKey, address: address, logger: logger)
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

    public static func sign(message: Data, privateKey: Data) throws -> Data {
        let ethSigner = EthSigner(privateKey: privateKey, cryptoUtils: CryptoUtils.shared)

        return try ethSigner.sign(message: message)
    }

    public static func sign(message: Data, seed: Data) throws -> Data {
        let privateKey = try Signer.privateKey(seed: seed, chain: .ethereum)

        return try sign(message: message, privateKey: privateKey.raw)
    }

}

extension Kit {

    public enum SyncError: Error {
        case notStarted
        case noNetworkConnection
    }

    public enum SendError: Error {
        case noAccountState
    }

}
