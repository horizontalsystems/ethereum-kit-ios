import Foundation
import RealmSwift
import RxSwift
import HSCryptoKit
import HSHDWalletKit

public class EthereumKit {
    private static let ethGasLimit = 21000
    private static let erc20GasLimit = 100000
    private static let ethRate: Decimal = pow(10, 18)

    private let disposeBag = DisposeBag()

    public weak var delegate: EthereumKitDelegate?

    private let wallet: Wallet

    private let realmFactory: RealmFactory
    private let addressValidator: AddressValidator
    private let geth: Geth
    private let gethProvider: IGethProviderProtocol

    private let reachabilityManager: ReachabilityManager

    private let refreshTimer: IPeriodicTimer
    private let refreshManager: RefreshManager

    private var balanceNotificationToken: NotificationToken?
    private var transactionsNotificationToken: NotificationToken?

    private var erc20Manager: Erc20Manager

    public var receiveAddress: String
    public var balance: Decimal = 0

    public var lastBlockHeight: Int? = nil

    public init(withWords words: [String], networkType: NetworkType, infuraKey: String, etherscanKey: String, debugPrints: Bool = false) {
        let wordsHash = words.joined().data(using: .utf8).map { CryptoKit.sha256sha256($0).toHexString() } ?? words[0]

        realmFactory = RealmFactory(realmFileName: "\(wordsHash)-\(networkType.rawValue).realm")
        addressValidator = AddressValidator()

        let network: Network

        switch networkType {
        case .mainNet:
            network = .mainnet
        case .testNet:
            network = .ropsten
        }

        do {
            wallet = try Wallet(seed: Mnemonic.seed(mnemonic: words), network: network, debugPrints: debugPrints)
        } catch {
            fatalError("Can't create hdWallet")
        }

        receiveAddress = wallet.address()
        let configuration = Configuration(
                network: network,
                nodeEndpoint: network.infura + infuraKey,
                etherscanAPIKey: etherscanKey,
                debugPrints: debugPrints
        )
        geth = Geth(configuration: configuration)
        gethProvider = GethProvider(geth: geth)

        reachabilityManager = ReachabilityManager()
        erc20Manager = Erc20Manager(reachabilityManager: reachabilityManager)

        refreshTimer = PeriodicTimer(interval: 30)
        refreshManager = RefreshManager(reachabilityManager: reachabilityManager, timer: refreshTimer)

        if let balanceString = realmFactory.realm.objects(EthereumBalance.self).filter("address = %@", wallet.address()).first?.value,
           let balanceDecimal = Decimal(string: balanceString) {
            balance = balanceDecimal / EthereumKit.ethRate
        }
        lastBlockHeight = realmFactory.realm.objects(EthereumBlockHeight.self).first?.blockHeight

        balanceNotificationToken = balanceResults.observe { [weak self] changeset in
            self?.handleBalance(changeset: changeset)
        }

        transactionsNotificationToken = transactionRealmResults.observe { [weak self] changeset in
            self?.handleTransactions(changeset: changeset)
        }

        erc20Manager.delegate = self
        refreshManager.delegate = self
    }

    public var debugInfo: String {
        var lines = [String]()

        lines.append("PUBLIC KEY: \(wallet.publicKey()) ADDRESS: \(wallet.address())")
        lines.append("TRANSACTION COUNT: \(transactionRealmResults.count)")

        return lines.joined(separator: "\n")
    }

    public func enable(contractAddress: String, decimal: Int) {
        erc20Manager.enable(contractAddress: contractAddress, decimal: decimal)
        realmFactory.realm.objects(EthereumBalance.self).filter("address = %@", contractAddress).forEach { ethereumBalance in
            update(ethereumBalance: ethereumBalance)
        }
    }

    public func disable(contractAddress: String) {
        erc20Manager.disable(contractAddress: contractAddress)
    }

    private func update(ethereumBalance: EthereumBalance) {
        if let balanceWei = Decimal(string: ethereumBalance.value) {
            let balanceDecimal = balanceWei / pow(10, ethereumBalance.decimal)
            if ethereumBalance.address == receiveAddress {
                balance = balanceDecimal
            }

            erc20Manager.holder(for: ethereumBalance.address)?.balance = balanceDecimal
        }
    }

    // Manage Kit methods

    public func start() {
        refreshAll()
    }

    public func refreshAll() {
        refresh()
        erc20Manager.holders.forEach { holder in
            erc20Refresh(contractAddress: holder.erc20.contractAddress)
        }
    }

    public func refresh() {
        let address = receiveAddress
        delegate?.kitStateUpdated(address: address, state: .syncing)
        Single.zip(updateBlockHeight, updateGasPrice, updateBalance(), updateTransactions()).subscribe(onSuccess: { [weak self] (blockHeight, _, _, _) in
            self?.lastBlockHeight = blockHeight
            self?.delegate?.kitStateUpdated(address: address, state: .synced)
            self?.refreshManager.didRefresh()
        }, onError: { error in
            self.delegate?.kitStateUpdated(address: address, state: .notSynced)
        }).disposed(by: disposeBag)
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
            var transactions = realm.objects(EthereumTransaction.self).filter("contractAddress = '' AND invalidTx = false").sorted(byKeyPath: "timestamp", ascending: false)

            if let fromHash = fromHash, let fromTransaction = transactions.filter("txHash = %@", fromHash).first {
                transactions = transactions.filter("timestamp < %@", fromTransaction.timestamp)
            }

            let results: [EthereumTransaction]
            if let limit = limit {
                results = Array(transactions.prefix(limit))
            } else {
                results = Array(transactions)
            }

            observer(.success(results))
            return Disposables.create()
        }
    }

    public var fee: Decimal {
        // only for standart transactions without data
        let gasPrice = (Decimal(ethereumGasPrice.gasPrice) * Decimal(EthereumKit.ethGasLimit)) / EthereumKit.ethRate
        return gasPrice
    }

    // Database objects
    private var ethereumGasPrice: EthereumGasPrice {
        let realm = realmFactory.realm
        guard let ethereumGasPrice = realm.objects(EthereumGasPrice.self).first else {
            let gasPrice = EthereumGasPrice()
            try? realm.write {
                realm.add(gasPrice, update: true)
            }
            return gasPrice
        }
        return ethereumGasPrice
    }

    private var transactionRealmResults: Results<EthereumTransaction> {
        return realmFactory.realm.objects(EthereumTransaction.self).sorted(byKeyPath: "timestamp", ascending: false)
    }

    private var balanceResults: Results<EthereumBalance> {
        return realmFactory.realm.objects(EthereumBalance.self).sorted(byKeyPath: "value", ascending: false)
    }

    // Database Update methods
    private func updateBalance(contractAddress: String? = nil, decimal: Int = 18) -> Single<Balance> {
        let realm = realmFactory.realm
        let address = contractAddress ?? wallet.address()

        return gethProvider.getBalance(address: wallet.address(), contractAddress: contractAddress, blockParameter: .latest).map { [weak self] balance in
            if let ethereumBalance = realm.objects(EthereumBalance.self).filter("address = %@", address).first {
                try? realm.write {
                    ethereumBalance.value = balance.wei.asString(withBase: 10)
                }
                self?.update(ethereumBalance: ethereumBalance)
            } else {
                let ethereumBalance = EthereumBalance(address: address, decimal: decimal, balance: balance)
                try? realm.write {
                    realm.add(ethereumBalance, update: true)
                }
                self?.update(ethereumBalance: ethereumBalance)
            }
            return balance
        }
    }

    private func updateTransactions(contractAddress: String? = nil) -> Single<Transactions> {
        let realm = realmFactory.realm
        let lastBlockHeight = realm.objects(EthereumTransaction.self).filter("contractAddress = %@", (contractAddress ?? "")).sorted(byKeyPath: "blockNumber", ascending: false).first?.blockNumber ?? 0

        return gethProvider.getTransactions(address: wallet.address(), contractAddress: contractAddress, startBlock: Int64(lastBlockHeight + 1)).map { transactions in
            try? realm.write {
                transactions.elements.map({ EthereumTransaction(transaction: $0) }).forEach {
                    realm.add($0, update: true)
                }
            }
            return transactions
        }
    }

    private var updateBlockHeight: Single<Int> {
        let realm = realmFactory.realm

        return gethProvider.getBlockNumber().map { blockNumber in
            if let ethereumBlockHeight = realm.objects(EthereumBlockHeight.self).first {
                try? realm.write {
                    ethereumBlockHeight.blockHeight = blockNumber
                }
            } else {
                let ethereumBlockHeight = EthereumBlockHeight(blockHeight: blockNumber)
                try? realm.write {
                    realm.add(ethereumBlockHeight, update: true)
                }
            }
            return blockNumber
        }
    }

    private var updateGasPrice: Single<Wei> {
        let realm = realmFactory.realm
        return gethProvider.getGasPrice().map { wei in
            guard let gasPrice = wei.toInt() else {
                // print("too big value")
                return Wei(EthereumGasPrice.normalGasPrice)
            }
            if let ethereumGasPrice = realm.objects(EthereumGasPrice.self).first {
                try? realm.write {

                    ethereumGasPrice.gasPrice = gasPrice
                }
            } else {
                let ethereumGasPrice = EthereumGasPrice(gasPrice: gasPrice)
                try? realm.write {
                    realm.add(ethereumGasPrice, update: true)
                }
            }
            return wei
        }
    }

    // Send transaction methods
    public func send(to address: String, value: Decimal, gasPrice: Int? = nil, completion: ((Error?) -> ())? = nil) {
        geth.getTransactionCount(of: wallet.address(), blockParameter: .pending) { result in
            switch result {
            case .success(let nonce):
                self.send(nonce: nonce, address: address, value: value, gasPrice: gasPrice ?? self.ethereumGasPrice.gasPrice, completion: completion)
            case .failure(let error):
                completion?(error)
            }
        }
    }

    private func convert(value: Decimal, completion: ((Error?) -> ())? = nil) -> BInt? {
        do {
            return try Converter.toWei(ether: value)
        } catch {
            completion?(error)
            return nil
        }
    }

    private func send(nonce: Int, address: String, value: Decimal, gasPrice: Int, completion: ((Error?) -> ())? = nil) {
        let selfAddress = wallet.address()

        // check value
        guard let weiString: String = convert(value: value, completion: completion)?.asString(withBase: 10) else {
            return
        }

        // make raw transaction
        let rawTransaction: RawTransaction

        let gas = Int(EthereumKit.ethGasLimit)
        rawTransaction = RawTransaction(wei: weiString, to: address, gasPrice: gasPrice, gasLimit: gas, nonce: nonce)
        do {
            let tx = try self.wallet.sign(rawTransaction: rawTransaction)

            // It returns the transaction ID.
            geth.sendRawTransaction(rawTransaction: tx) { [weak self] result in
                switch result {
                case .success(let sentTransaction):
                    let transaction = EthereumTransaction(txHash: sentTransaction.id, from: selfAddress, to: address, gas: gas, gasPrice: gasPrice, value: weiString, timestamp: Int(Date().timeIntervalSince1970))
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
        guard realm.objects(EthereumTransaction.self).filter("primary = %@", transaction.primary).first == nil else {
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
                    inserted: insertions.map { collection[$0] }.filter { !$0.invalidTx },
                    updated: modifications.map { collection[$0] }.filter { !$0.invalidTx },
                    deleted: deletions
            )
        }
    }

    private func handleBalance(changeset: RealmCollectionChange<Results<EthereumBalance>>) {
        if case let .update(collection, _, insertions, modifications) = changeset {
            let union: [EthereumBalance] = (insertions.map { collection[$0] }) + modifications.map { collection[$0] }
            union.forEach { balance in
                if let balanceWei = Decimal(string: balance.value) {
                    let balanceDecimal = balanceWei / pow(10, balance.decimal)
                    delegate?.balanceUpdated(ethereumKit: self, address: balance.address, balance: balanceDecimal)
                }
            }
        }
    }

}

// ERC20 Extension
public extension EthereumKit {

    public func erc20Refresh(contractAddress: String) {
        guard let holder = erc20Manager.holder(for: contractAddress) else {
            return
        }
        let erc20 = holder.erc20

        delegate?.kitStateUpdated(address: contractAddress, state: .syncing)
        Single.zip(updateBalance(contractAddress: contractAddress, decimal: erc20.decimal), updateTransactions(contractAddress: contractAddress)).subscribe(onSuccess: { [weak self] (_, _) in
            self?.delegate?.kitStateUpdated(address: contractAddress, state: .synced)
            holder.didRefresh()
        }, onError: { error in
            self.delegate?.kitStateUpdated(address: contractAddress, state: .notSynced)
        }).disposed(by: disposeBag)
    }

    public var erc20Fee: Decimal {
        // only for erc20 coin maximum fee
        let gasPrice = (Decimal(ethereumGasPrice.gasPrice) * Decimal(EthereumKit.erc20GasLimit)) / EthereumKit.ethRate
        return gasPrice
    }

    public func erc20Balance(address: String) -> Decimal {
        return erc20Manager.holder(for: address)?.balance ?? 0
    }

    public func erc20Transactions(contractAddress: String, fromHash: String? = nil, limit: Int? = nil) -> Single<[EthereumTransaction]> {
        return Single.create { observer in
            let realm = self.realmFactory.realm
            var transactions = realm.objects(EthereumTransaction.self).filter("contractAddress = %@", contractAddress).sorted(byKeyPath: "timestamp", ascending: false)

            if let fromHash = fromHash, let fromTransaction = transactions.filter("txHash = %@", fromHash).first {
                transactions = transactions.filter("timestamp < %@", fromTransaction.timestamp)
            }

            let results: [EthereumTransaction]
            if let limit = limit {
                results = Array(transactions.prefix(limit))
            } else {
                results = Array(transactions)
            }

            observer(.success(results))
            return Disposables.create()
        }
    }

    private func erc20BalanceResults(contractAddress: String) -> Results<EthereumBalance> {
        return realmFactory.realm.objects(EthereumBalance.self).filter("address = %@", contractAddress).sorted(byKeyPath: "value", ascending: false)
    }

    public func erc20Send(to address: String, contractAddress: String, value: Decimal, gasPrice: Int? = nil, completion: ((Error?) -> ())? = nil) {
        guard let contract = erc20Manager.holder(for: contractAddress)?.erc20 else {
            completion?(EthereumKitError.contractError(.contractNotExist(contractAddress)))
            return
        }

        let gasPrice = gasPrice ?? ethereumGasPrice.gasPrice
        geth.getTransactionCount(of: wallet.address(), blockParameter: .pending) { result in
            switch result {
            case .success(let nonce):
                self.erc20Send(nonce: nonce, address: address, contract: contract, value: value, gasPrice: gasPrice, completion: completion)
            case .failure(let error):
                completion?(error)
            }
        }
    }

    private func parameterData(address: String, amount: String, contract: ERC20, completion: ((Error?) -> ())? = nil) -> Data? {
        do {
            return try contract.generateDataParameter(toAddress: address, amount: amount)
        } catch {
            completion?(error)
            return nil
        }
    }

    private func erc20Send(nonce: Int, address: String, contract: ERC20, value: Decimal, gasPrice: Int, completion: ((Error?) -> ())? = nil) {
        let selfAddress = wallet.address()

        // check value
        guard let weiString: String = try? contract.power(amount: String(describing: value)).asString(withBase: 10) else {
            completion?(EthereumKitError.convertError(.failedToConvert(value)))
            return
        }

        // make raw transaction
        let rawTransaction: RawTransaction
        let gasLimit = EthereumKit.erc20GasLimit

        // check right contract parameters create
        guard let params = parameterData(address: address, amount: String(describing: value), contract: contract, completion: completion) else {
            return
        }
        rawTransaction = RawTransaction(wei: "0", to: contract.contractAddress, gasPrice: gasPrice, gasLimit: gasLimit, nonce: nonce, data: params)
        do {
            let tx = try self.wallet.sign(rawTransaction: rawTransaction)

            // It returns the transaction ID.
            geth.sendRawTransaction(rawTransaction: tx) { [weak self] result in
                switch result {
                case .success(let sentTransaction):
                    let transaction = EthereumTransaction(txHash: sentTransaction.id, from: selfAddress, to: address, contractAddress: contract.contractAddress, gas: gasLimit, gasPrice: gasPrice, value: weiString, timestamp: Int(Date().timeIntervalSince1970), input: params.toHexString().addHexPrefix())
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

}

public protocol EthereumKitDelegate: class {
    func transactionsUpdated(ethereumKit: EthereumKit, inserted: [EthereumTransaction], updated: [EthereumTransaction], deleted: [Int])
    func balanceUpdated(ethereumKit: EthereumKit, address: String, balance: Decimal)
    func kitStateUpdated(address: String?, state: EthereumKit.KitState)
}

extension EthereumKit {

    public enum NetworkType {
        case mainNet
        case testNet

        var rawValue: String {
            return "eth-\(self)"
        }
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
        delegate?.kitStateUpdated(address: nil, state: .notSynced)
    }

}

extension EthereumKit: IErc20ManagerRefreshDelegate {

    func onRefresh(contractAddress: String) {
        erc20Refresh(contractAddress: contractAddress)
    }

}