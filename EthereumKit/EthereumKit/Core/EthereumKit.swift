import RxSwift
import HSCryptoKit
import HSHDWalletKit

public class EthereumKit {
    private let gasLimit = 21_000

    public let lastBlockHeightSignal = Signal()
    public let syncStateSignal = Signal()
    public let balanceSignal = Signal()
    public let transactionsSubject = PublishSubject<[TransactionInfo]>()

    private let blockchain: IBlockchain
    private let addressValidator: IAddressValidator
    private let transactionBuilder: TransactionBuilder
    private let state: EthereumKitState

    init(blockchain: IBlockchain, addressValidator: IAddressValidator, transactionBuilder: TransactionBuilder, state: EthereumKitState = EthereumKitState()) {
        self.blockchain = blockchain
        self.addressValidator = addressValidator
        self.transactionBuilder = transactionBuilder
        self.state = state

        state.balance = blockchain.balance
        state.lastBlockHeight = blockchain.lastBlockHeight
    }

}

// Public API Extension

extension EthereumKit {

    public func start() {
        blockchain.start()
    }

    public func stop() {
        blockchain.stop()
    }

    public func clear() {
        blockchain.stop()
        blockchain.clear()
        state.clear()
    }

    public var lastBlockHeight: Int? {
        return state.lastBlockHeight
    }

    public var balance: String? {
        return state.balance?.asString(withBase: 10)
    }

    public var syncState: SyncState {
        return blockchain.syncState
    }

    public var receiveAddress: String {
        return blockchain.address.toEIP55Address()
    }

    public var receiveAddressData: Data {
        return blockchain.address
    }

    public func validate(address: String) throws {
        try addressValidator.validate(address: address)
    }

    public func fee(gasPrice: Int) -> Decimal {
        return Decimal(gasPrice) * Decimal(gasLimit)
    }

    public func transactionsSingle(fromHash: String? = nil, limit: Int? = nil) -> Single<[TransactionInfo]> {
        return blockchain.transactionsSingle(fromHash: fromHash.flatMap { Data(hex: $0) }, limit: limit)
                .map { $0.map { TransactionInfo(transaction: $0) } }
    }

    public func sendSingle(to: Data, value: String, transactionInput: Data, gasPrice: Int, gasLimit: Int) -> Single<TransactionInfo> {
        guard let value = BInt(value) else {
            return Single.error(EthereumKit.SendError.invalidValue)
        }

        let rawTransaction = transactionBuilder.rawTransaction(gasPrice: gasPrice, gasLimit: gasLimit, to: to, value: value, data: transactionInput)
        return blockchain.sendSingle(rawTransaction: rawTransaction)
                .map { TransactionInfo(transaction: $0) }
    }

    public func sendSingle(to: String, value: String, gasPrice: Int) -> Single<TransactionInfo> {
        guard let to = Data(hex: to) else {
            return Single.error(SendError.invalidAddress)
        }

        guard let value = BInt(value) else {
            return Single.error(SendError.invalidValue)
        }

        let rawTransaction = transactionBuilder.rawTransaction(gasPrice: gasPrice, gasLimit: gasLimit, to: to, value: value)
        return blockchain.sendSingle(rawTransaction: rawTransaction)
                .map { TransactionInfo(transaction: $0) }
    }

    public var debugInfo: String {
        var lines = [String]()

        lines.append("ADDRESS: \(blockchain.address)")

        return lines.joined(separator: "\n")
    }

    public func getLogsSingle(address: Data?, topics: [Any], fromBlock: Int, toBlock: Int, pullTimestamps: Bool) -> Single<[EthereumLog]> {
        return blockchain.getLogsSingle(address: address, topics: topics, fromBlock: fromBlock, toBlock: toBlock, pullTimestamps: pullTimestamps)
    }

    public func getStorageAt(contractAddress: Data, positionData: Data, blockHeight: Int) -> Single<Data> {
        return blockchain.getStorageAt(contractAddress: contractAddress, positionData: positionData, blockHeight: blockHeight)
    }

}


extension EthereumKit: IBlockchainDelegate {

    func onUpdate(lastBlockHeight: Int) {
        guard state.lastBlockHeight != lastBlockHeight else {
            return
        }

        state.lastBlockHeight = lastBlockHeight

        lastBlockHeightSignal.notify()
    }

    func onUpdate(balance: BInt) {
        guard state.balance != balance else {
            return
        }

        state.balance = balance

        balanceSignal.notify()
    }

    func onUpdate(syncState: SyncState) {
        syncStateSignal.notify()
    }

    func onUpdate(transactions: [Transaction]) {
        transactionsSubject.onNext(transactions.map { TransactionInfo(transaction: $0) })
    }

}

extension EthereumKit {

    public static func instance(privateKey: Data, syncMode: SyncMode, networkType: NetworkType = .mainNet, etherscanApiKey: String, walletId: String = "default", minLogLevel: Logger.Level = .error) -> EthereumKit {
        let logger = Logger(minLogLevel: minLogLevel)

        let publicKey = Data(CryptoKit.createPublicKey(fromPrivateKeyData: privateKey, compressed: false).dropFirst())
        let address = Data(CryptoUtils.shared.sha3(publicKey).suffix(20))

        let network: INetwork = networkType.network
        let transactionSigner = TransactionSigner(network: network, privateKey: privateKey)
        let transactionBuilder = TransactionBuilder()
        let networkManager = NetworkManager(logger: logger)
        let transactionsProvider: ITransactionsProvider = EtherscanApiProvider(networkManager: networkManager, network: network, etherscanApiKey: etherscanApiKey)

        var blockchain: IBlockchain

        switch syncMode {
        case .api(let infuraProjectId):
            let storage: IApiStorage = ApiGrdbStorage(databaseFileName: "api-\(walletId)-\(networkType)")
            let rpcApiProvider: IRpcApiProvider = InfuraApiProvider(networkManager: networkManager, network: network, infuraProjectId: infuraProjectId)
            blockchain = ApiBlockchain.instance(storage: storage, network: network, transactionSigner: transactionSigner, transactionBuilder: transactionBuilder, address: address, rpcApiProvider: rpcApiProvider, transactionsProvider: transactionsProvider, logger: logger)
        case .spv(let nodePrivateKey):
            let storage: ISpvStorage = SpvGrdbStorage(databaseFileName: "spv-\(walletId)-\(networkType)")

            let nodePublicKey = Data(CryptoKit.createPublicKey(fromPrivateKeyData: nodePrivateKey, compressed: false).dropFirst())
            let nodeKey = ECKey(privateKey: nodePrivateKey, publicKeyPoint: ECPoint(nodeId: nodePublicKey))

            blockchain = SpvBlockchain.instance(storage: storage, transactionsProvider: transactionsProvider, transactionSigner: transactionSigner, transactionBuilder: transactionBuilder, network: network, address: address, nodeKey: nodeKey, logger: logger)
        }

        let addressValidator: IAddressValidator = AddressValidator()
        let ethereumKit = EthereumKit(blockchain: blockchain, addressValidator: addressValidator, transactionBuilder: transactionBuilder)

        blockchain.delegate = ethereumKit

        return ethereumKit
    }

    public static func instance(words: [String], syncMode wordsSyncMode: WordsSyncMode, networkType: NetworkType = .mainNet, etherscanApiKey: String, walletId: String = "default", minLogLevel: Logger.Level = .error) throws -> EthereumKit {
        let coinType: UInt32 = networkType == .mainNet ? 60 : 1

        let hdWallet = HDWallet(seed: Mnemonic.seed(mnemonic: words), coinType: coinType, xPrivKey: 0, xPubKey: 0)
        let privateKey = try hdWallet.privateKey(account: 0, index: 0, chain: .external).raw

        let syncMode: SyncMode

        switch wordsSyncMode {
        case .api(let infuraProjectId): syncMode = .api(infuraProjectId: infuraProjectId)
        case .spv: syncMode = .spv(nodePrivateKey: try hdWallet.privateKey(account: 100, index: 100, chain: .external).raw)
        }

        return instance(privateKey: privateKey, syncMode: syncMode, networkType: networkType, etherscanApiKey: etherscanApiKey, walletId: walletId, minLogLevel: minLogLevel)
    }

}

extension EthereumKit {

    public enum NetworkError: Error {
        case invalidUrl
        case mappingError
        case noConnection
        case serverError(status: Int, data: Any?)
    }

    public enum SendError: Error {
        case invalidAddress
        case invalidContractAddress
        case invalidValue
        case infuraError(message: String)
    }

    public enum ApiError: Error {
        case invalidData
    }

    public enum SyncState {
        case synced
        case syncing
        case notSynced
    }

    public enum SyncMode {
        case api(infuraProjectId: String)
        case spv(nodePrivateKey: Data)
    }

    public enum WordsSyncMode {
        case api(infuraProjectId: String)
        case spv
    }

    public enum NetworkType {
        case mainNet
        case ropsten
        case kovan

        var network: INetwork {
            switch self {
            case .mainNet:
                return Ropsten()
            case .ropsten, .kovan:
                return Ropsten()
            }
        }
    }

}
