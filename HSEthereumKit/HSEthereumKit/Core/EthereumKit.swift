import Foundation
import RxSwift

public class EthereumKit {
    private let disposeBag = DisposeBag()

    public weak var delegate: IEthereumKitDelegate?

    private let blockchain: IBlockchain
    private let storage: IStorage
    private let addressValidator: IAddressValidator
    private let state: EthereumKitState
    private let delegateQueue: DispatchQueue

    init(blockchain: IBlockchain, storage: IStorage, addressValidator: IAddressValidator, state: EthereumKitState = EthereumKitState(), delegateQueue: DispatchQueue = .main) {
        self.blockchain = blockchain
        self.storage = storage
        self.addressValidator = addressValidator
        self.state = state
        self.delegateQueue = delegateQueue

        state.balance = storage.balance(forAddress: blockchain.ethereumAddress)
        state.lastBlockHeight = storage.lastBlockHeight
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
        storage.clear()
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
        return blockchain.ethereumAddress
    }

    public func register(contractAddress: String, delegate: IEthereumKitDelegate) {
        guard !state.has(contractAddress: contractAddress) else {
            return
        }

        state.add(contractAddress: contractAddress, delegate: delegate)
        state.set(balance: storage.balance(forAddress: contractAddress), contractAddress: contractAddress)

        blockchain.register(contractAddress: contractAddress)
    }

    public func unregister(contractAddress: String) {
        blockchain.unregister(contractAddress: contractAddress)
        state.remove(contractAddress: contractAddress)
    }

    public func validate(address: String) throws {
        try addressValidator.validate(address: address)
    }

    public func fee(gasPriceInWei: Int? = nil) -> Decimal {
        // only for standard transactions without data
        return Decimal(gasPriceInWei ?? blockchain.gasPriceInWei.mediumPriority) * Decimal(blockchain.gasLimitEthereum)
    }

    public func transactionsSingle(fromHash: String? = nil, limit: Int? = nil) -> Single<[EthereumTransaction]> {
        return storage.transactionsSingle(fromHash: fromHash, limit: limit, contractAddress: nil)
    }

    public func sendSingle(to address: String, amount: String, gasPriceInWei: Int? = nil) -> Single<EthereumTransaction> {
        return blockchain.sendSingle(to: address, amount: amount, gasPriceInWei: gasPriceInWei)
    }

    public var debugInfo: String {
        var lines = [String]()

//        lines.append("PUBLIC KEY: \(hdWallet.publicKey()) ADDRESS: \(hdWallet.address())")
        lines.append("ADDRESS: \(blockchain.ethereumAddress)")

        return lines.joined(separator: "\n")
    }

}

// Public ERC20 API Extension

extension EthereumKit {

    public func feeErc20(gasPriceInWei: Int? = nil) -> Decimal {
        // only for erc20 coin maximum fee
        return Decimal(gasPriceInWei ?? blockchain.gasPriceInWei.mediumPriority) * Decimal(blockchain.gasLimitErc20)
    }

    public func balanceErc20(contractAddress: String) -> String? {
        return state.balance(contractAddress: contractAddress)
    }

    public func syncStateErc20(contractAddress: String) -> SyncState {
        return blockchain.syncState(contractAddress: contractAddress)
    }

    public func transactionsErc20Single(contractAddress: String, fromHash: String? = nil, limit: Int? = nil) -> Single<[EthereumTransaction]> {
        return storage.transactionsSingle(fromHash: fromHash, limit: limit, contractAddress: contractAddress)
    }

    public func sendErc20Single(to address: String, contractAddress: String, amount: String, gasPriceInWei: Int? = nil) -> Single<EthereumTransaction> {
        return blockchain.sendErc20Single(to: address, contractAddress: contractAddress, amount: amount, gasPriceInWei: gasPriceInWei)
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

    public static func ethereumKit(words: [String], walletId: String, testMode: Bool, infuraKey: String, etherscanKey: String, debugPrints: Bool = false) throws -> EthereumKit {
        let storage = ApiGrdbStorage(databaseFileName: "\(walletId)-\(testMode)")
        let blockchain = try ApiBlockchain.apiBlockchain(storage: storage, words: words, testMode: testMode, infuraKey: infuraKey, etherscanKey: etherscanKey, debugPrints: debugPrints)
        let addressValidator = AddressValidator()

        let ethereumKit = EthereumKit(blockchain: blockchain, storage: storage, addressValidator: addressValidator)

        blockchain.delegate = ethereumKit

        return ethereumKit
    }

    public static func ethereumKitSpv(words: [String], walletId: String, testMode: Bool, minLogLevel: Logger.Level = .verbose) -> EthereumKit {
        let logger = Logger(minLogLevel: minLogLevel)

        let storage = SpvGrdbStorage(databaseFileName: "\(walletId)-\(testMode)")
        let blockchain = SpvBlockchain.spvBlockchain(storage: storage, words: words, testMode: testMode, logger: logger)
        let addressValidator = AddressValidator()

        let ethereumKit = EthereumKit(blockchain: blockchain, storage: storage, addressValidator: addressValidator)

        blockchain.delegate = ethereumKit

        return ethereumKit
    }

}

extension EthereumKit {

    public enum SyncState {
        case synced
        case syncing
        case notSynced
    }

}
