import RxSwift
import EthereumKit
import HSCryptoKit

public class Erc20Kit {
    private let gasLimit = 100_000

    private let disposeBag = DisposeBag()

    private let ethereumKit: EthereumKit
    private let transactionManager: ITransactionManager
    private let balanceManager: IBalanceManager
    private let tokenHolder: ITokenHolder

    init(ethereumKit: EthereumKit, transactionManager: ITransactionManager, balanceManager: IBalanceManager, tokenHolder: ITokenHolder = TokenHolder()) {
        self.ethereumKit = ethereumKit
        self.transactionManager = transactionManager
        self.balanceManager = balanceManager
        self.tokenHolder = tokenHolder

        ethereumKit.lastBlockHeightObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onNext: { [weak self] _ in
                    self?.onUpdateLastBlockHeight()
                })
                .disposed(by: disposeBag)

        ethereumKit.syncStateObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onNext: { [weak self] in
                    self?.onUpdateSyncState(syncState: $0)
                })
                .disposed(by: disposeBag)
    }

    private func startTransactionsSync() {
        transactionManager.sync()
    }

    private func convert(address: String) throws -> Data {
        guard let contractAddress = Data(hex: address) else {
            throw TokenError.invalidAddress
        }

        return contractAddress
    }

    private func set(syncState: Erc20Kit.SyncState, contractAddress: Data) {
        try? tokenHolder.set(syncState: syncState, contractAddress: contractAddress)
        try? tokenHolder.syncStateSubject(contractAddress: contractAddress).onNext(syncState)
    }

    private func setAll(syncState: Erc20Kit.SyncState) {
        for contractAddress in tokenHolder.contractAddresses {
            set(syncState: syncState, contractAddress: contractAddress)
        }
    }

    private func onUpdateSyncState(syncState: EthereumKit.SyncState) {
        switch syncState {
        case .notSynced: setAll(syncState: .notSynced)
        case .syncing: setAll(syncState: .syncing)
        case .synced: startTransactionsSync()
        }
    }

    private func onUpdateLastBlockHeight() {
        guard ethereumKit.syncState == .synced else {
            return
        }

        startTransactionsSync()
    }

}

extension Erc20Kit {

    public func syncState(contractAddress: String) throws -> SyncState {
        return try tokenHolder.syncState(contractAddress: try convert(address: contractAddress))
    }

    public func balance(contractAddress: String) throws -> String? {
        return try tokenHolder.balance(contractAddress: try convert(address: contractAddress)).value?.asString(withBase: 10)
    }

    public func fee(gasPrice: Int) -> Decimal {
        return Decimal(gasPrice) * Decimal(gasLimit)
    }

    public func sendSingle(contractAddress: String, to: String, value: String, gasPrice: Int) throws -> Single<TransactionInfo> {
        let contractAddress = try convert(address: contractAddress)
        let to = try convert(address: to)

        guard let value = BInt(value) else {
            throw SendError.invalidValue
        }

        return transactionManager.sendSingle(contractAddress: contractAddress, to: to, value: value, gasPrice: gasPrice, gasLimit: gasLimit)
                .map({ TransactionInfo(transaction: $0) })
                .do(onSuccess: { [weak self] transaction in
                    try? self?.tokenHolder.transactionsSubject(contractAddress: contractAddress).onNext([transaction])
                })
    }

    public func transactionsSingle(contractAddress: String, from: (hash: String, index: Int)?, limit: Int?) throws -> Single<[TransactionInfo]> {
        let from = try from.map {
            (hash: try convert(address: $0.hash), index: $0.index)
        }

        return transactionManager.transactionsSingle(contractAddress: try convert(address: contractAddress), from: from, limit: limit)
                .map { transactions in
                    transactions.map {
                        TransactionInfo(transaction: $0)
                    }
                }
    }

    public func register(contractAddress: String) throws {
        let contractAddress = try convert(address: contractAddress)
        let balance = balanceManager.balance(contractAddress: contractAddress)

        tokenHolder.register(contractAddress: contractAddress, balance: balance)
    }

    public func unregister(contractAddress: String) throws {
        let contractAddress = try convert(address: contractAddress)

        try tokenHolder.unregister(contractAddress: contractAddress)
    }

    public func syncStateObservable(contractAddress: String) throws -> Observable<SyncState> {
        let contractAddress = try convert(address: contractAddress)

        return try tokenHolder.syncStateSubject(contractAddress: contractAddress).asObservable()
    }

    public func balanceObservable(contractAddress: String) throws -> Observable<String> {
        let contractAddress = try convert(address: contractAddress)

        return try tokenHolder.balanceSubject(contractAddress: contractAddress).asObservable()
    }

    public func transactionsObservable(contractAddress: String) throws -> Observable<[TransactionInfo]> {
        let contractAddress = try convert(address: contractAddress)

        return try tokenHolder.transactionsSubject(contractAddress: contractAddress).asObservable()
    }

    public func clear() {
        tokenHolder.clear()
        transactionManager.clear()
        balanceManager.clear()
    }

}

extension Erc20Kit: ITransactionManagerDelegate {

    func onSyncSuccess(transactions: [Transaction]) {
        let transactionsData: [Data: [Transaction]] = Dictionary(grouping: transactions, by: { $0.contractAddress })

        for (contractAddress, transactions) in transactionsData {
            try? tokenHolder.transactionsSubject(contractAddress: contractAddress).onNext(transactions.map { TransactionInfo(transaction: $0) })
        }

        for contractAddress in tokenHolder.contractAddresses {
            if let lastTransactionBlockHeight = transactionManager.lastTransactionBlockHeight(contractAddress: contractAddress),
               lastTransactionBlockHeight > balanceManager.balance(contractAddress: contractAddress).blockHeight ?? 0
            {
                balanceManager.sync(blockHeight: lastTransactionBlockHeight, contractAddress: contractAddress)
            } else {
                set(syncState: .synced, contractAddress: contractAddress)
            }
        }
    }

    func onSyncTransactionsError() {
        setAll(syncState: .notSynced)
    }

}

extension Erc20Kit: IBalanceManagerDelegate {

    func onSyncBalanceSuccess(contractAddress: Data) {
        set(syncState: .synced, contractAddress: contractAddress)
    }

    func onSyncBalanceError(contractAddress: Data) {
        set(syncState: .notSynced, contractAddress: contractAddress)
    }

    func onUpdate(balance: TokenBalance, contractAddress: Data) {
        try? tokenHolder.set(balance: balance, contractAddress: contractAddress)

        if let value = balance.value {
            try? tokenHolder.balanceSubject(contractAddress: contractAddress).onNext(value.asString(withBase: 10))
        }
    }

}

extension Erc20Kit {

    public static func instance(ethereumKit: EthereumKit, minLogLevel: Logger.Level = .verbose) -> Erc20Kit {
        let address = ethereumKit.receiveAddressData

        let storage: ITransactionStorage & ITokenBalanceStorage = GrdbStorage(databaseFileName: "erc20_tokens_db")

        let dataProvider: IDataProvider = DataProvider(ethereumKit: ethereumKit)
        let transactionBuilder: ITransactionBuilder = TransactionBuilder()
        var transactionManager: ITransactionManager = TransactionManager(address: address, storage: storage, dataProvider: dataProvider, transactionBuilder: transactionBuilder)
        var balanceManager: IBalanceManager = BalanceManager(address: address, storage: storage, dataProvider: dataProvider)

        let erc20Kit = Erc20Kit(ethereumKit: ethereumKit, transactionManager: transactionManager, balanceManager: balanceManager)

        transactionManager.delegate = erc20Kit
        balanceManager.delegate = erc20Kit

        return erc20Kit
    }

}

extension Erc20Kit {

    public enum TokenError: Error {
        case invalidAddress
        case notRegistered
        case alreadyRegistered
    }

    public enum SendError: Error {
        case invalidAddress
        case invalidContractAddress
        case invalidValue
    }

    public enum SyncState: Int {
        case notSynced = 0
        case syncing = 1
        case synced = 2
    }

}
