import Foundation
import RealmSwift
import RxSwift
import HSCryptoKit
import HSHDWalletKit

public class EthereumKit {
    private let disposeBag = DisposeBag()

    public weak var delegate: EthereumKitDelegate?

    private let wallet: Wallet

    private let realmFactory: RealmFactory
    private let addressValidator: AddressValidator
    private let geth: Geth
    private let gethProvider: IGethProviderProtocol

    private let refreshTimer: IPeriodicTimer
    private let reachabilityManager: ReachabilityManager
    private let refreshManager: RefreshManager
    private var balanceNotificationToken: NotificationToken?
    private var transactionsNotificationToken: NotificationToken?

    public var balance: BInt = BInt(0)
    public var lastBlockHeight: Int? = nil

    public init(withWords words: [String], coin: Coin, infuraKey: String, etherscanKey: String, debugPrints: Bool = false) {
        let wordsHash = words.joined().data(using: .utf8).map { CryptoKit.sha256sha256($0).toHexString() } ?? words[0]

        realmFactory = RealmFactory(realmFileName: "\(wordsHash)-\(coin.rawValue).realm")
        addressValidator = AddressValidator()

        let network: Network

        switch coin {
        case .ethereum(let networkType):
            switch networkType {
            case .mainNet:
                network = .mainnet
            case .testNet:
                network = .ropsten
            }
        }

        do {
            wallet = try Wallet(seed: Mnemonic.seed(mnemonic: words), network: network, debugPrints: debugPrints)
        } catch {
            fatalError("Can't create hdWallet")
        }

        let configuration = Configuration(
                network: network,
                nodeEndpoint: network.infura + infuraKey,
                etherscanAPIKey: etherscanKey,
                debugPrints: debugPrints
        )
        geth = Geth(configuration: configuration)
        gethProvider = GethProvider(geth: geth)

        reachabilityManager = ReachabilityManager()
        refreshTimer = PeriodicTimer(interval: 30)
        refreshManager = RefreshManager(reachabilityManager: reachabilityManager, timer: refreshTimer)

        balanceNotificationToken = balanceResults.observe { [weak self] changeset in
            self?.handleBalance(changeset: changeset)
        }

        transactionsNotificationToken = transactionRealmResults.observe { [weak self] changeset in
            self?.handleTransactions(changeset: changeset)
        }

        refreshManager.delegate = self
    }

    public var debugInfo: String {
        var lines = [String]()

        lines.append("PUBLIC KEY: \(wallet.publicKey()) ADDRESS: \(wallet.address())")
        lines.append("TRANSACTION COUNT: \(transactionRealmResults.count)")

        return lines.joined(separator: "\n")
    }

    // Manage Kit methods

    public func start() {
        refresh()
    }

    public func refresh() {
        delegate?.kitStateUpdated(state: .syncing)
        Single.zip(updateBalance, updateBlockHeight, updateTransactions, updateGasPrice).subscribe(
                onSuccess: { [weak self] (balance, blockNumber, _, _) in
                    self?.balance = BInt(balance.wei.asString(withBase: 10)) ?? BInt(0)
                    self?.lastBlockHeight = blockNumber

                    self?.delegate?.kitStateUpdated(state: .synced)
                    self?.refreshManager.didRefresh()
                },
                onError: { error in
                    self.delegate?.kitStateUpdated(state: .notSynced)
                    print(error)
                }
        ).disposed(by: disposeBag)
    }

    public func clear() throws {
        let realm = realmFactory.realm

        try realm.write {
            realm.deleteAll()
        }
    }

    public func validate(address: String) throws {
        try addressValidator.validate(address: address)
    }

    public func transactions(fromHash: String? = nil, limit: Int? = nil) -> Single<[EthereumTransaction]> {
        return Single.create { observer in
            let realm = self.realmFactory.realm
            var transactions = realm.objects(EthereumTransaction.self).sorted(byKeyPath: "timestamp", ascending: false)

            if let fromHash = fromHash, let fromTransaction = realm.objects(EthereumTransaction.self).filter("txHash = %@", fromHash).first {
                transactions = transactions.filter("timestamp < %@", fromTransaction.timestamp)
            }

            var results = Array(transactions)
            if let limit = limit {
                results = Array(transactions.prefix(limit))
            }

            observer(.success(results))
            return Disposables.create()
        }
    }

    public var fee: Int {
        // only for standart transactions without data
        let gas = ethereumGas
        return gas.gasPriceGWei * gas.gasLimit
    }

    // Database objects
    private var ethereumGas: EthereumGas {
        let realm = realmFactory.realm
        let address = wallet.address()

        guard let ethereumGas = realm.objects(EthereumGas.self).filter("address = %@", address).first else {
            let gas = EthereumGas(address: address)
            try? realm.write {
                realm.add(gas, update: true)
            }
            return gas
        }
        return ethereumGas
    }

    private var transactionRealmResults: Results<EthereumTransaction> {
        return realmFactory.realm.objects(EthereumTransaction.self).sorted(byKeyPath: "timestamp", ascending: false)
    }

    private var balanceResults: Results<EthereumBalance> {
        return realmFactory.realm.objects(EthereumBalance.self).sorted(byKeyPath: "value", ascending: false)
    }

    // Database Update methods
    private var updateBalance: Single<Balance> {
        let realm = realmFactory.realm
        let address = wallet.address()

        return gethProvider.getBalance(address: address, blockParameter: .latest).map { balance in
            if let ethereumBalance = realm.objects(EthereumBalance.self).filter("address = %@", address).first {
                try? realm.write {
                    ethereumBalance.value = balance.wei.asString(withBase: 10)
                }
            } else {
                let ethereumBalance = EthereumBalance(address: address, balance: balance)
                try? realm.write {
                    realm.add(ethereumBalance, update: true)
                }
            }
            return balance
        }
    }

    private var updateBlockHeight: Single<Int> {
        let realm = realmFactory.realm

        return gethProvider.getBlockNumber().map { blockNumber in
            if let ethereumBlockNumber = realm.objects(EthereumBlockHeight.self).filter("blockKey = %@", EthereumBlockHeight.key).first {
                try? realm.write {
                    ethereumBlockNumber.blockHeight = blockNumber
                }
            } else {
                let ethereumBalance = EthereumBlockHeight(blockHeight: blockNumber)
                try? realm.write {
                    realm.add(ethereumBalance, update: true)
                }
            }
            return blockNumber
        }
    }

    private var updateGasPrice: Single<Wei> {
        let realm = realmFactory.realm
        let address = wallet.address()

        return gethProvider.getGasPrice().map { wei in
            let price = Converter.toGWei(wei: wei) ?? EthereumGas.normalGasPriceInGWei
            if let ethereumGas = realm.objects(EthereumGas.self).filter("address = %@", address).first {
                try? realm.write {
                    ethereumGas.gasPriceGWei = price
                }
            } else {
                let ethereumGas = EthereumGas(address: address, priceInGWei: price)
                try? realm.write {
                    realm.add(ethereumGas, update: true)
                }
            }
            return wei
        }
    }

    private var updateTransactions: Single<Transactions> {
        let realm = realmFactory.realm

        let lastBlockHeight = realm.objects(EthereumTransaction.self).sorted(byKeyPath: "blockNumber", ascending: false).first?.blockNumber ?? 0

        return gethProvider.getTransactions(address: wallet.address(), startBlock: Int64(lastBlockHeight + 1)).map { transactions in
            try? realm.write {
                transactions.elements.map({ EthereumTransaction(transaction: $0) }).forEach {
                    realm.add($0, update: true)
                }
            }
            return transactions
        }
    }

    // Send transaction methods
    public var receiveAddress: String {
        return wallet.address()
    }

    public func send(to address: String, value: Double, gasPrice: Int? = nil, completion: ((Error?) -> ())? = nil) {
        let price = Converter.toWei(GWei: gasPrice ?? ethereumGas.gasPriceGWei)
        geth.getTransactionCount(of: wallet.address(), blockParameter: .pending) { result in
            switch result {
            case .success(let nonce):
                self.send(nonce: nonce, address: address, value: value, gasPrice: price, gasLimit: EthereumGas.normalGasLimit, completion: completion)
            case .failure(let error):
                completion?(error)
            }
        }
    }

    private func convert(ether: Double, completion: ((Error?) -> ())? = nil) -> BInt? {
        do {
            let amount = (ether as NSNumber).decimalValue
            return try Converter.toWei(ether: amount)
        } catch {
            completion?(error)
        }
        return nil
    }

    private func send(nonce: Int, address: String, value: Double, gasPrice: Int, gasLimit: Int, completion: ((Error?) -> ())? = nil) {
        let selfAddress = wallet.address()
        guard let wei: BInt = convert(ether: value, completion: completion) else {
            return
        }
        let rawTransaction = RawTransaction(value: wei, to: address, gasPrice: gasPrice, gasLimit: gasLimit, nonce: nonce)
        do {
            let tx = try self.wallet.sign(rawTransaction: rawTransaction)

            // It returns the transaction ID.
            geth.sendRawTransaction(rawTransaction: tx) { [weak self] result in
                switch result {
                case .success(let sentTransaction):
                    let transaction = EthereumTransaction(txHash: sentTransaction.id, from: selfAddress, to: address, gas: gasLimit, gasPrice: gasPrice, value: wei.asString(withBase: 10), timestamp: Int(Date().timeIntervalSince1970))
                    self?.addSentTransaction(transaction: transaction)
                    completion?(nil)
                case .failure(let error):
                    completion?(error)
                }
            }
        } catch {
            completion?(error)
        }
    }

    private func addSentTransaction(transaction: EthereumTransaction) {
        let realm = realmFactory.realm
        guard realm.objects(EthereumTransaction.self).filter("txHash = %@", transaction.txHash).first == nil else {
            // no need to save
            return
        }
        try? realm.write {
            realm.add(transaction, update: true)
        }
    }

    // Handlers
    private func handleTransactions(changeset: RealmCollectionChange<Results<EthereumTransaction>>) {
        if case let .update(collection, deletions, insertions, modifications) = changeset {
            delegate?.transactionsUpdated(
                    ethereumKit: self,
                    inserted: insertions.map { collection[$0] },
                    updated: modifications.map { collection[$0] },
                    deleted: deletions
            )
        }
    }

    private func handleBalance(changeset: RealmCollectionChange<Results<EthereumBalance>>) {
        if case .update = changeset {
            delegate?.balanceUpdated(ethereumKit: self, balance: balance)
        }
    }

}

public protocol EthereumKitDelegate: class {
    func transactionsUpdated(ethereumKit: EthereumKit, inserted: [EthereumTransaction], updated: [EthereumTransaction], deleted: [Int])
    func balanceUpdated(ethereumKit: EthereumKit, balance: BInt)
    func kitStateUpdated(state: EthereumKit.KitState)
}

extension EthereumKit {

    public enum Coin {
        case ethereum(network: NetworkType)

        var rawValue: String {
            switch self {
            case .ethereum(let network):
                return "eth-\(network)"
            }
        }
    }

    public enum NetworkType {
        case mainNet
        case testNet
    }

    public enum KitState {
        case synced
        case syncing
        case notSynced
    }

}

extension EthereumKit: IRefreshKitDelegate {

    func onRefresh() {
        refresh()
    }

    func onDisconnect() {
        delegate?.kitStateUpdated(state: .notSynced)
    }

}
