import RxSwift
import HSCryptoKit
import HSHDWalletKit

public class EthereumKit {
    private let gasLimit = 21_000
    private let gasLimitErc20 = 100_000

    private let disposeBag = DisposeBag()

    public weak var delegate: IEthereumKitDelegate?

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
    }

    public func clear() {
        delegate = nil

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

    public func register(contractAddress: String, delegate: IEthereumKitDelegate) {
        guard let contractAddress = Data(hex: contractAddress) else {
            return
        }

        guard !state.has(contractAddress: contractAddress) else {
            return
        }

        state.add(contractAddress: contractAddress, delegate: delegate)
        state.set(balance: blockchain.balanceErc20(contractAddress: contractAddress), contractAddress: contractAddress)

        blockchain.register(contractAddress: contractAddress)
    }

    public func unregister(contractAddress: String) {
        guard let contractAddress = Data(hex: contractAddress) else {
            return
        }

        blockchain.unregister(contractAddress: contractAddress)
        state.remove(contractAddress: contractAddress)
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

//        lines.append("PUBLIC KEY: \(hdWallet.publicKey()) ADDRESS: \(hdWallet.address())")
        lines.append("ADDRESS: \(blockchain.address)")

        return lines.joined(separator: "\n")
    }

}

// Public ERC20 API Extension

extension EthereumKit {

    public func feeErc20(gasPrice: Int) -> Decimal {
        return Decimal(gasPrice) * Decimal(gasLimitErc20)
    }

    public func balanceErc20(contractAddress: String) -> String? {
        guard let contractAddress = Data(hex: contractAddress) else {
            return nil
        }

        return state.balance(contractAddress: contractAddress)?.asString(withBase: 10)
    }

    public func syncStateErc20(contractAddress: String) -> SyncState {
        guard let contractAddress = Data(hex: contractAddress) else {
            return .notSynced
        }

        return blockchain.syncStateErc20(contractAddress: contractAddress)
    }

    public func transactionsErc20Single(contractAddress: String, fromHash: String? = nil, limit: Int? = nil) -> Single<[TransactionInfo]> {
        guard let contractAddress = Data(hex: contractAddress) else {
            return Single.just([])
        }

        return blockchain.transactionsErc20Single(contractAddress: contractAddress, fromHash: fromHash.flatMap { Data(hex: $0) }, limit: limit)
                .map { $0.compactMap { TransactionInfo(transaction: $0) } }
    }

    public func sendErc20Single(contractAddress: String, to: String, value: String, gasPrice: Int) -> Single<TransactionInfo> {
        guard let contractAddress = Data(hex: contractAddress) else {
            return Single.error(SendError.invalidContractAddress)
        }

        guard let to = Data(hex: to) else {
            return Single.error(SendError.invalidAddress)
        }

        guard let value = BInt(value) else {
            return Single.error(SendError.invalidValue)
        }

        let rawTransaction = transactionBuilder.rawErc20Transaction(contractAddress: contractAddress, gasPrice: gasPrice, gasLimit: gasLimit, to: to, value: value)
        return blockchain.sendSingle(rawTransaction: rawTransaction)
                .map { TransactionInfo(transaction: $0) }
    }

}

extension EthereumKit: IBlockchainDelegate {

    func onUpdate(lastBlockHeight: Int) {
        guard state.lastBlockHeight != lastBlockHeight else {
            return
        }

        state.lastBlockHeight = lastBlockHeight

        delegateQueue.async { [weak self] in
            self?.delegate?.onUpdateLastBlockHeight()
            self?.state.erc20Delegates.forEach { delegate in
                delegate.onUpdateLastBlockHeight()
            }
        }
    }

    func onUpdate(balance: BInt) {
        guard state.balance != balance else {
            return
        }

        state.balance = balance

        delegateQueue.async { [weak self] in
            self?.delegate?.onUpdateBalance()
        }
    }

    func onUpdateErc20(balance: BInt, contractAddress: Data) {
        guard state.balance(contractAddress: contractAddress) != balance else {
            return
        }

        state.set(balance: balance, contractAddress: contractAddress)

        delegateQueue.async { [weak self] in
            self?.state.delegate(contractAddress: contractAddress)?.onUpdateBalance()
        }
    }

    func onUpdate(syncState: SyncState) {
        delegate?.onUpdateSyncState()
    }

    func onUpdateErc20(syncState: SyncState, contractAddress: Data) {
        delegateQueue.async { [weak self] in
            self?.state.delegate(contractAddress: contractAddress)?.onUpdateSyncState()
        }
    }

    func onUpdate(transactions: [Transaction]) {
        delegateQueue.async { [weak self] in
            self?.delegate?.onUpdate(transactions: transactions.map { TransactionInfo(transaction: $0) })
        }
    }

    func onUpdateErc20(transactions: [Transaction], contractAddress: Data) {
        delegateQueue.async { [weak self] in
            self?.state.delegate(contractAddress: contractAddress)?.onUpdate(transactions: transactions.map { TransactionInfo(transaction: $0) })
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
        var blockchain: IBlockchain

        switch syncMode {
        case .api(let infuraProjectId, let etherscanApiKey):
            let storage: IApiStorage = ApiGrdbStorage(databaseFileName: "api-\(walletId)-\(networkType)")
            blockchain = ApiBlockchain.instance(storage: storage, network: network, transactionSigner: transactionSigner, transactionBuilder: transactionBuilder, address: address, infuraProjectId: infuraProjectId, etherscanApiKey: etherscanApiKey, logger: logger)
        case .spv(let nodePrivateKey):
            let storage: ISpvStorage = SpvGrdbStorage(databaseFileName: "spv-\(walletId)-\(networkType)")

            let nodePublicKey = Data(CryptoKit.createPublicKey(fromPrivateKeyData: nodePrivateKey, compressed: false).dropFirst())
            let nodeKey = ECKey(privateKey: nodePrivateKey, publicKeyPoint: ECPoint(nodeId: nodePublicKey))

            blockchain = SpvBlockchain.spvBlockchain(storage: storage, transactionSigner: transactionSigner, transactionBuilder: transactionBuilder, network: network, address: address, nodeKey: nodeKey, logger: logger)
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
        case api(infuraProjectId: String, etherscanApiKey: String)
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
