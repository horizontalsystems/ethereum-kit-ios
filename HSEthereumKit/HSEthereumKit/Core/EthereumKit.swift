import RxSwift
import HSCryptoKit
import HSHDWalletKit

public class EthereumKit {
    private let gasLimit = 21_000
    private var delegates = [IEthereumKitDelegate]()
    private var requests = [Int: IEthereumKitDelegate]()

    private let blockchain: IBlockchain
    private let addressValidator: IAddressValidator
    private let transactionBuilder: TransactionBuilder
    private let state: EthereumKitState
    private let delegateQueue: DispatchQueue

    init(blockchain: IBlockchain, addressValidator: IAddressValidator, transactionBuilder: TransactionBuilder, state: EthereumKitState = EthereumKitState(), delegateQueue: DispatchQueue = .main) {
        self.blockchain = blockchain
        self.addressValidator = addressValidator
        self.transactionBuilder = transactionBuilder
        self.state = state
        self.delegateQueue = delegateQueue

        state.balance = blockchain.balance
        state.lastBlockHeight = blockchain.lastBlockHeight
    }

}

// Public API Extension

extension EthereumKit {

    public func start() {
        blockchain.start()
        for delegate in delegates {
            delegate.onStart()
        }
    }

    public func clear() {
        blockchain.clear()
        state.clear()
        for delegate in delegates {
            delegate.onClear()
        }
        delegates = []
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

    public func add(delegate: IEthereumKitDelegate) {
        delegates.append(delegate)
    }

//    public func getStorageAt(contractAddress: String, position: String, blockNumber: Int?) -> Single<String> {
//        return blockchain.getStorageAt(contractAddress: contractAddress, position: position, blockNumber: blockNumber)
//    }

    public func send(request: IRequest, by delegate: IEthereumKitDelegate) {
        self.requests[request.id] = delegate
        blockchain.send(request: request)
    }

}


extension EthereumKit: IBlockchainDelegate {

    func onUpdate(lastBlockHeight: Int) {
        guard state.lastBlockHeight != lastBlockHeight else {
            return
        }

        state.lastBlockHeight = lastBlockHeight

        delegateQueue.async { [weak self] in
            print("DELEGATES COUNT: \(self?.delegates.count)")
            self?.delegates.forEach { $0.onUpdateLastBlockHeight() }
        }
    }

    func onUpdate(balance: BInt) {
        guard state.balance != balance else {
            return
        }

        state.balance = balance

        delegateQueue.async { [weak self] in
            self?.delegates.forEach { $0.onUpdateBalance() }
        }
    }

    func onUpdate(syncState: SyncState) {
        delegates.forEach { $0.onUpdateSyncState() }
    }

    func onUpdate(transactions: [Transaction]) {
        delegateQueue.async { [weak self] in
            self?.delegates.forEach { $0.onUpdate(transactions: transactions.map { TransactionInfo(transaction: $0) }) }
        }
    }

    func onResponse(response: IResponse) {
        if let delegate = requests[response.id] {
            delegate.onResponse(response: response)
        }
    }

}

extension EthereumKit {

    public static func instance(privateKey: Data, syncMode: SyncMode, networkType: NetworkType = .mainNet, walletId: String = "default", minLogLevel: Logger.Level = .error) -> EthereumKit {
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

    public static func instance(words: [String], syncMode: SyncMode, networkType: NetworkType = .mainNet, walletId: String = "default", minLogLevel: Logger.Level = .error) throws -> EthereumKit {
        let coinType: UInt32 = networkType == .mainNet ? 60 : 1

        let hdWallet = HDWallet(seed: Mnemonic.seed(mnemonic: words), coinType: coinType, xPrivKey: 0, xPubKey: 0)
        let privateKey = try hdWallet.privateKey(account: 0, index: 0, chain: .external).raw

        return instance(privateKey: privateKey, syncMode: syncMode, networkType: networkType, walletId: walletId, minLogLevel: minLogLevel)
    }

}

extension EthereumKit {

    public enum SendError: Error {
        case invalidAddress
        case invalidContractAddress
        case invalidValue
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
