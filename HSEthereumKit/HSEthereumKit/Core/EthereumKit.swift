import Foundation
import RxSwift

public class EthereumKit {
    private let disposeBag = DisposeBag()

    public weak var delegate: IEthereumKitDelegate?

    private let blockchain: IBlockchain
    private let storage: IStorage
    private let addressValidator: IAddressValidator
    private let configProvider: IConfigProvider
    private let state: EthereumKitState

    init(blockchain: IBlockchain, storage: IStorage, addressValidator: IAddressValidator, configProvider: IConfigProvider, state: EthereumKitState = EthereumKitState()) {
        self.blockchain = blockchain
        self.storage = storage
        self.addressValidator = addressValidator
        self.configProvider = configProvider
        self.state = state

        state.balance = storage.balance(forAddress: blockchain.ethereumAddress)
        state.lastBlockHeight = storage.lastBlockHeight
    }

}

// Public API Extension

extension EthereumKit {

    public func start() {
        guard !state.isSyncing else {
            return
        }

        blockchain.start()
    }

    public func stop() {
        blockchain.stop()
    }

    public func clear() {
        blockchain.clear()
        storage.clear()
        state.clear()
    }

    public var lastBlockHeight: Int? {
        return state.lastBlockHeight
    }

    public var balance: Decimal {
        return state.balance ?? 0
    }

    public var syncState: SyncState {
        return state.syncState ?? .notSynced
    }

    public var receiveAddress: String {
        return blockchain.ethereumAddress
    }

    public func register(contractAddress: String, decimal: Int, delegate: IEthereumKitDelegate) {
        guard !state.has(contractAddress: contractAddress) else {
            return
        }

        state.add(contractAddress: contractAddress, decimal: decimal, delegate: delegate)
        blockchain.register(contractAddress: contractAddress, decimal: decimal)
    }

    public func unregister(contractAddress: String) {
        blockchain.unregister(contractAddress: contractAddress)
        state.remove(contractAddress: contractAddress)
    }

    public func validate(address: String) throws {
        try addressValidator.validate(address: address)
    }

    public func fee(gasPrice: Decimal? = nil) -> Decimal {
        // only for standard transactions without data
        return (gasPrice ?? blockchain.gasPrice) * Decimal(configProvider.ethereumGasLimit)
    }

    public func transactions(fromHash: String? = nil, limit: Int? = nil) -> Single<[EthereumTransaction]> {
        return storage.transactionsSingle(fromHash: fromHash, limit: limit, contractAddress: nil)
    }

    public func send(to address: String, amount: Decimal, gasPrice: Decimal? = nil, onSuccess: (() -> ())? = nil, onError: ((Error) -> ())? = nil) {
        blockchain.send(to: address, amount: amount, gasPrice: gasPrice, onSuccess: onSuccess, onError: onError)
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

    public func erc20Fee(gasPrice: Decimal? = nil) -> Decimal {
        // only for erc20 coin maximum fee
        return (gasPrice ?? blockchain.gasPrice) * Decimal(configProvider.erc20GasLimit)
    }

    public func erc20Balance(contractAddress: String) -> Decimal {
        return state.balance(contractAddress: contractAddress) ?? 0
    }

    public func erc20SyncState(contractAddress: String) -> SyncState {
        return state.syncState(contractAddress: contractAddress) ?? .notSynced
    }

    public func erc20Transactions(contractAddress: String, fromHash: String? = nil, limit: Int? = nil) -> Single<[EthereumTransaction]> {
        return storage.transactionsSingle(fromHash: fromHash, limit: limit, contractAddress: contractAddress)
    }

    public func erc20Send(to address: String, contractAddress: String, amount: Decimal, gasPrice: Decimal? = nil, onSuccess: (() -> ())? = nil, onError: ((Error) -> ())? = nil) {
        blockchain.erc20Send(to: address, contractAddress: contractAddress, amount: amount, gasPrice: gasPrice, onSuccess: onSuccess, onError: onError)
    }

}

extension EthereumKit: IBlockchainDelegate {

    func onUpdate(lastBlockHeight: Int) {
        state.lastBlockHeight = lastBlockHeight

        delegate?.onUpdateLastBlockHeight()
        state.erc20Delegates.forEach { delegate in
            delegate.onUpdateLastBlockHeight()
        }
    }

    func onUpdate(balance: Decimal) {
        state.balance = balance
        delegate?.onUpdateBalance()
    }

    func onUpdateErc20(balance: Decimal, contractAddress: String) {
        state.set(balance: balance, contractAddress: contractAddress)
        state.delegate(contractAddress: contractAddress)?.onUpdateBalance()
    }

    func onUpdate(syncState: SyncState) {
        state.syncState = syncState
        delegate?.onUpdateSyncState()
    }

    func onUpdateErc20(syncState: SyncState, contractAddress: String) {
        state.set(syncState: syncState, contractAddress: contractAddress)
        state.delegate(contractAddress: contractAddress)?.onUpdateSyncState()
    }

    func onUpdate(transactions: [EthereumTransaction]) {
        delegate?.onUpdate(transactions: transactions)
    }

    func onUpdateErc20(transactions: [EthereumTransaction], contractAddress: String) {
        state.delegate(contractAddress: contractAddress)?.onUpdate(transactions: transactions)
    }

}

extension EthereumKit {

    public static func ethereumKit(words: [String], walletId: String, testMode: Bool, infuraKey: String, etherscanKey: String, debugPrints: Bool = false) throws -> EthereumKit {
        let storage = GrdbStorage(databaseFileName: "\(walletId)-\(testMode)")
        let blockchain = try GethBlockchain(storage: storage, words: words, testMode: testMode, infuraKey: infuraKey, etherscanKey: etherscanKey, debugPrints: debugPrints)
        let addressValidator = AddressValidator()
        let configProvider = ConfigProvider()

        let ethereumKit = EthereumKit(blockchain: blockchain, storage: storage, addressValidator: addressValidator, configProvider: configProvider)

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
