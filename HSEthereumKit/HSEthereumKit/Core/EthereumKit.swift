import Foundation
import RealmSwift
import RxSwift
import CryptoSwift

public class EthereumKit {
    private static let infuraKey = "2a1306f1d12f4c109a4d4fb9be46b02e"
    private static let etherscanKey = "GKNHXT22ED7PRVCKZATFZQD1YI7FK9AAYE"

    let disposeBag = DisposeBag()

    public weak var delegate: EthereumKitDelegate?

    let wallet: Wallet

    let realmFactory: RealmFactory
    let addressValidator: AddressValidator
    let geth: Geth

    private var balanceNotificationToken: NotificationToken?
    private var transactionsNotificationToken: NotificationToken?

    public init(withWords words: [String], coin: Coin, debugPrints: Bool = false) {
        let wordsHash = words.joined().data(using: .utf8).map { Crypto.doubleSHA256($0).toHexString() } ?? words[0]

        let realmFileName = "\(wordsHash)-\(coin.rawValue).realm"

        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let realmConfiguration = Realm.Configuration(fileURL: documentsUrl?.appendingPathComponent(realmFileName))

        realmFactory = RealmFactory(configuration: realmConfiguration)
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
            wallet = try Wallet(seed: try Mnemonic.createSeed(mnemonic: words), network: network, debugPrints: debugPrints)
        } catch {
            fatalError("Can't create hdWallet")
        }

        let configuration = Configuration(
                network: network,
                nodeEndpoint: network.infura + EthereumKit.infuraKey,
                etherscanAPIKey: EthereumKit.etherscanKey,
                debugPrints: debugPrints
        )
        geth = Geth(configuration: configuration)

        balanceNotificationToken = balanceResults.observe { [weak self] changeset in
            self?.handleBalance(changeset: changeset)
        }

        transactionsNotificationToken = transactionRealmResults.observe { [weak self] changeset in
            self?.handleTransactions(changeset: changeset)
        }

    }

    public var debugInfo: String {
        var lines = [String]()

        lines.append("PUBLIC KEY: \(wallet.publicKey()) ADDRESS: \(wallet.address())")
        lines.append("TRANSACTION COUNT: \(transactions.count)")

        return lines.joined(separator: "\n")
    }

    // Manage Kit methods

    public func start() {
        refresh()
    }

    public func refresh() {
        let completion: ((Error?) -> ()) = { error in
            if let error = error {
                print("Error \(error.localizedDescription)")
            }
        }
        updateBalance(completion: completion)
        updateBlockHeight(completion: completion)
        updateTransactions(completion: completion)
        updateGasPrice()
    }

    public func clear() throws {
        let realm = realmFactory.realm

        try realm.write {
            realm.deleteAll()
        }
    }

    // Wallet data getters
    public var progress: Double {
        return 1
    }

    public func validate(address: String) throws {
        try addressValidator.validate(address: address)
    }

    public var balance: BInt {
        let balanceString = realmFactory.realm.objects(EthereumBalance.self).filter("address = %@", wallet.address()).first?.value ?? "0"

        return BInt(balanceString) ?? BInt(0)
    }

    public var lastBlockHeight: Int? {
        return realmFactory.realm.objects(EthereumBlockHeight.self).filter("blockKey = %@", EthereumBlockHeight.key).first?.blockHeight
    }

    public var transactions: [EthereumTransaction] {
        return transactionRealmResults.map { $0 }
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
    private func updateBalance(completion: ((Error?) -> ())? = nil) {
        let realm = realmFactory.realm
        let address = wallet.address()

        geth.getBalance(of: address) { result in
            switch result {
            case .success(let balance):
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
                completion?(nil)
            case .failure(let error): completion?(error)
            }
        }
    }

    private func updateBlockHeight(completion: ((Error?) -> ())? = nil) {
        let realm = realmFactory.realm

        geth.getBlockNumber() { result in
            switch result {
            case .success(let blockNumber):
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
                completion?(nil)
            case .failure(let error): completion?(error)
            }
        }
    }

    private func updateGasPrice(completion: ((Error?) -> ())? = nil) {
        let realm = realmFactory.realm
        let address = wallet.address()

        geth.getGasPrice() { result in
            switch result {
            case .success(let wei):
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
                completion?(nil)
            case .failure(let error): completion?(error)
            }
        }
    }

    private func updateTransactions(completion: ((Error?) -> ())? = nil) {
        let realm = realmFactory.realm

        geth.getTransactions(address: wallet.address(), startBlock: Int64((lastBlockHeight ?? 0) + 1)) { result in
            switch result {
            case .success(let transactions):
                try? realm.write {
                    transactions.elements.map({ EthereumTransaction(transaction: $0) }).forEach {
                        realm.add($0, update: true)
                    }
                }
                completion?(nil)
            case .failure(let error): completion?(error)
            }
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
            self.geth.sendRawTransaction(rawTransaction: tx) { result in
                switch result {
                case .success(let sentTransaction):
                    let transaction = EthereumTransaction(txHash: sentTransaction.id, from: selfAddress, to: address, gas: gasLimit, gasPrice: gasPrice, value: wei.asString(withBase: 10), timestamp: Int(Date().timeIntervalSince1970))
                    self.addSentTransaction(transaction: transaction)
                case .failure(let error): completion?(error)
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

}
