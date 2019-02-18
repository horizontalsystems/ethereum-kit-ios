import Foundation
import RxSwift

public class EthereumKit {
    private let disposeBag = DisposeBag()

    public weak var delegate: EthereumKitDelegate?

    private let storage: IStorage
    private let reachabilityManager: ReachabilityManager
    private let addressValidator: AddressValidator

    private var blockchain: IBlockchain

    private var erc20Holders = [String: Erc20Holder]()
    private var currentGasPrice: Decimal?
    private var ethereumAddress: String

    public private(set) var balance: Decimal = 0 {
        didSet {
            delegate?.onUpdateBalance()
        }
    }
    public private(set) var lastBlockHeight: Int? {
        didSet {
            delegate?.onUpdateLastBlockHeight()
            erc20Holders.values.forEach { $0.delegate.onUpdateLastBlockHeight() }
        }
    }
    public private(set) var state: SyncState = .notSynced {
        didSet {
            delegate?.onUpdateState()
        }
    }

    public init(withWords words: [String], walletId: String, testMode: Bool, infuraKey: String, etherscanKey: String, debugPrints: Bool = false) throws {
        reachabilityManager = ReachabilityManager()
        addressValidator = AddressValidator()

        storage = GrdbStorage(databaseFileName: "\(walletId)-\(testMode)")

        blockchain = try Blockchain(storage: storage, reachabilityManager: reachabilityManager, words: words, testMode: testMode, infuraKey: infuraKey, etherscanKey: etherscanKey, debugPrints: debugPrints)
        ethereumAddress = blockchain.ethereumAddress

        blockchain.delegate = self

        balance = storage.balance(forAddress: ethereumAddress) ?? 0
        lastBlockHeight = storage.lastBlockHeight
        currentGasPrice = storage.gasPrice
    }

    private var gasPrice: Decimal {
        return currentGasPrice ?? Blockchain.defaultGasPrice
    }

}

// Public API Extension

extension EthereumKit {

    public func start() {
        guard state != .syncing else {
            return
        }
        for holder in erc20Holders.values {
            if holder.state == .syncing {
                return
            }
        }

        blockchain.start()
    }

    public func stop() {
        blockchain.stop()
    }

    public func clear() throws {
        blockchain.clear()
        erc20Holders = [:]
        storage.clear()
    }

    public var receiveAddress: String {
        return ethereumAddress
    }

    public func register(token: Erc20KitDelegate) {
        guard erc20Holders[token.contractAddress] == nil else {
            return
        }

        let holder = Erc20Holder(delegate: token, balance: storage.balance(forAddress: token.contractAddress) ?? 0)
        erc20Holders[token.contractAddress] = holder

        blockchain.register(contractAddress: token.contractAddress, decimal: token.decimal)
    }

    public func unregister(contractAddress: String) {
        blockchain.unregister(contractAddress: contractAddress)
        erc20Holders.removeValue(forKey: contractAddress)
    }

    public func validate(address: String) throws {
        try addressValidator.validate(address: address)
    }

    public var fee: Decimal {
        // only for standard transactions without data
        return gasPrice * Decimal(Blockchain.ethGasLimit)
    }

    public func transactions(fromHash: String? = nil, limit: Int? = nil) -> Single<[EthereumTransaction]> {
        return storage.transactionsSingle(fromHash: fromHash, limit: limit, contractAddress: nil)
    }

    public func send(to address: String, value: Decimal, completion: ((Error?) -> ())? = nil) {
        blockchain.send(to: address, value: value, gasPrice: gasPrice, completion: completion)
    }

    public var debugInfo: String {
        var lines = [String]()

//        lines.append("PUBLIC KEY: \(hdWallet.publicKey()) ADDRESS: \(hdWallet.address())")

        return lines.joined(separator: "\n")
    }

}

// Public ERC20 API Extension

extension EthereumKit {

    public var erc20Fee: Decimal {
        // only for erc20 coin maximum fee
        return gasPrice * Decimal(Blockchain.erc20GasLimit)
    }

    public func erc20Balance(contractAddress: String) -> Decimal {
        return erc20Holders[contractAddress]?.balance ?? 0
    }

    public func erc20State(contractAddress: String) -> SyncState {
        return erc20Holders[contractAddress]?.state ?? .notSynced
    }

    public func erc20Transactions(contractAddress: String, fromHash: String? = nil, limit: Int? = nil) -> Single<[EthereumTransaction]> {
        return storage.transactionsSingle(fromHash: fromHash, limit: limit, contractAddress: contractAddress)
    }

    public func erc20Send(to address: String, contractAddress: String, value: Decimal, completion: ((Error?) -> ())? = nil) {
        blockchain.erc20Send(to: address, contractAddress: contractAddress, value: value, gasPrice: gasPrice, completion: completion)
    }

}

extension EthereumKit: IBlockchainDelegate {

    func onUpdate(lastBlockHeight: Int) {
        self.lastBlockHeight = lastBlockHeight
    }

    func onUpdate(gasPrice: Decimal) {
        currentGasPrice = gasPrice
    }

    func onUpdate(state: SyncState) {
        self.state = state
    }

    func onUpdateErc20(state: SyncState, contractAddress: String) {
        erc20Holders[contractAddress]?.state = state
    }

    func onUpdate(balance: Decimal) {
        self.balance = balance
    }

    func onUpdateErc20(balance: Decimal, contractAddress: String) {
        erc20Holders[contractAddress]?.balance = balance
    }

    func onUpdate(transactions: [EthereumTransaction]) {
        delegate?.onUpdate(transactions: transactions)
    }

    func onUpdateErc20(transactions: [EthereumTransaction], contractAddress: String) {
        erc20Holders[contractAddress]?.delegate.onUpdate(transactions: transactions)
    }

}
