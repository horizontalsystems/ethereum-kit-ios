import RxSwift
import HSCryptoKit

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
        return state.balance
    }

    public var syncState: SyncState {
        return blockchain.syncState
    }

    public var receiveAddress: String {
        return blockchain.address.string
    }

    public func register(contractAddress: String, delegate: IEthereumKitDelegate) {
        guard !state.has(contractAddress: contractAddress) else {
            return
        }

        state.add(contractAddress: contractAddress, delegate: delegate)
        state.set(balance: blockchain.balanceErc20(contractAddress: contractAddress), contractAddress: contractAddress)

        blockchain.register(contractAddress: contractAddress)
    }

    public func unregister(contractAddress: String) {
        blockchain.unregister(contractAddress: contractAddress)
        state.remove(contractAddress: contractAddress)
    }

    public func validate(address: String) throws {
        try addressValidator.validate(address: address)
    }

    public func fee(gasPrice: Int) -> Decimal {
        return Decimal(gasPrice) * Decimal(gasLimit)
    }

    public func transactionsSingle(fromHash: String? = nil, limit: Int? = nil) -> Single<[EthereumTransaction]> {
        return blockchain.transactionsSingle(fromHash: fromHash, limit: limit)
    }

    public func sendSingle(to toAddress: String, amount: String, gasPrice: Int) -> Single<EthereumTransaction> {
        guard let value = BInt(amount) else {
            return Single.error(SendError.invalidAmount)
        }

        let rawTransaction = transactionBuilder.rawTransaction(gasPrice: gasPrice, gasLimit: gasLimit, to: Address(string: toAddress), value: value)
        return blockchain.sendSingle(rawTransaction: rawTransaction)
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
        return state.balance(contractAddress: contractAddress)
    }

    public func syncStateErc20(contractAddress: String) -> SyncState {
        return blockchain.syncStateErc20(contractAddress: contractAddress)
    }

    public func transactionsErc20Single(contractAddress: String, fromHash: String? = nil, limit: Int? = nil) -> Single<[EthereumTransaction]> {
        return blockchain.transactionsErc20Single(contractAddress: contractAddress, fromHash: fromHash, limit: limit)
    }

    public func sendErc20Single(contractAddress: String, to address: String, amount: String, gasPrice: Int) -> Single<EthereumTransaction> {
        guard let value = BInt(amount) else {
            return Single.error(SendError.invalidAmount)
        }

        let rawTransaction = transactionBuilder.rawErc20Transaction(contractAddress: Address(string: contractAddress), gasPrice: gasPrice, gasLimit: gasLimit, to: Address(string: address), value: value)
        return blockchain.sendSingle(rawTransaction: rawTransaction)
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

    func onUpdate(balance: String) {
        guard state.balance != balance else {
            return
        }

        state.balance = balance

        delegateQueue.async { [weak self] in
            self?.delegate?.onUpdateBalance()
        }
    }

    func onUpdateErc20(balance: String, contractAddress: String) {
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

    func onUpdateErc20(syncState: SyncState, contractAddress: String) {
        delegateQueue.async { [weak self] in
            self?.state.delegate(contractAddress: contractAddress)?.onUpdateSyncState()
        }
    }

    func onUpdate(transactions: [EthereumTransaction]) {
        delegateQueue.async { [weak self] in
            self?.delegate?.onUpdate(transactions: transactions)
        }
    }

    func onUpdateErc20(transactions: [EthereumTransaction], contractAddress: String) {
        delegateQueue.async { [weak self] in
            self?.state.delegate(contractAddress: contractAddress)?.onUpdate(transactions: transactions)
        }
    }

}

extension EthereumKit {

    public static func instance(privateKey: Data, syncMode: SyncMode, networkType: NetworkType = .mainNet, walletId: String = "default", minLogLevel: Logger.Level = .verbose) -> EthereumKit {
        let logger = Logger(minLogLevel: minLogLevel)

        let publicKey = Data(CryptoKit.createPublicKey(fromPrivateKeyData: privateKey, compressed: false).dropFirst())
        let addressData = Data(CryptoUtils.shared.sha3(publicKey).suffix(20))
        let address = Address(data: addressData)

        let network: INetwork = networkType.network
        let transactionSigner = TransactionSigner(network: network, privateKey: privateKey)
        let transactionBuilder = TransactionBuilder()
        var blockchain: IBlockchain

        switch syncMode {
        case .api(let infuraKey, let etherscanKey):
            let storage: IApiStorage = ApiGrdbStorage(databaseFileName: "api-\(walletId)-\(networkType)")
            blockchain = ApiBlockchain.instance(storage: storage, network: network, transactionSigner: transactionSigner, transactionBuilder: transactionBuilder, address: address, infuraKey: infuraKey, etherscanKey: etherscanKey, logger: logger)
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

}

extension EthereumKit {

    public enum SendError: Error {
        case invalidAmount
    }

    public enum SyncState {
        case synced
        case syncing
        case notSynced
    }

    public enum SyncMode {
        case api(infuraKey: String, etherscanKey: String)
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
