import RxSwift
import EthereumKit
import HSCryptoKit
import BigInt

public class Erc20Kit {
    private let gasLimit: Int
    private let disposeBag = DisposeBag()

    private let ethereumKit: EthereumKit
    private let transactionManager: ITransactionManager
    private let balanceManager: IBalanceManager

    private let state: KitState

    init(ethereumKit: EthereumKit, transactionManager: ITransactionManager, balanceManager: IBalanceManager, gasLimit: Int = 1_000_000, state: KitState = KitState()) {
        self.ethereumKit = ethereumKit
        self.transactionManager = transactionManager
        self.balanceManager = balanceManager
        self.gasLimit = gasLimit
        self.state = state

        onUpdateSyncState(syncState: ethereumKit.syncState)
        state.balance = balanceManager.balance

        ethereumKit.syncStateObservable
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] in
                    self?.onUpdateSyncState(syncState: $0)
                })
                .disposed(by: disposeBag)
    }

    private func convert(address: String) throws -> Data {
        guard let address = Data(hex: address) else {
            throw TokenError.invalidAddress
        }

        return address
    }

    private func onUpdateSyncState(syncState: EthereumKit.SyncState) {
        switch syncState {
        case .notSynced: state.syncState = .notSynced
        case .syncing: state.syncState = .syncing
        case .synced:
            state.syncState = .syncing
            balanceManager.sync()
        }
    }

}

extension Erc20Kit {

    public var syncState: SyncState {
        state.syncState
    }

    public var balance: String? {
        state.balance?.description
    }

    public func sendSingle(to: String, value: String, gasPrice: Int, gasLimit: Int) throws -> Single<TransactionInfo> {
        let to = try convert(address: to)

        guard let value = BigUInt(value) else {
            throw ValidationError.invalidValue
        }

        return transactionManager.sendSingle(to: to, value: value, gasPrice: gasPrice, gasLimit: gasLimit)
                .map({ TransactionInfo(transaction: $0) })
                .do(onSuccess: { [weak self] transaction in
                    self?.state.transactionsSubject.onNext([transaction])
                })
    }

    public func transactionsSingle(from: (hash: String, interTransactionIndex: Int)?, limit: Int?) throws -> Single<[TransactionInfo]> {
        let from = try from.map {
            (hash: try convert(address: $0.hash), interTransactionIndex: $0.interTransactionIndex)
        }

        return transactionManager.transactionsSingle(from: from, limit: limit)
                .map { transactions in
                    transactions.map {
                        TransactionInfo(transaction: $0)
                    }
                }
    }

    public var syncStateObservable: Observable<SyncState> {
        state.syncStateSubject.asObservable()
    }

    public var balanceObservable: Observable<String> {
        state.balanceSubject.asObservable()
    }

    public var transactionsObservable: Observable<[TransactionInfo]> {
        state.transactionsSubject.asObservable()
    }

    public func estimateGas(to: String, contractAddress: String, value: String) -> Single<Int> {
        guard let amountValue = BigUInt(value) else {
            return Single.error(ValidationError.invalidValue)
        }

        do {
            let toAddress = try convert(address: to)
            let data = transactionManager.transactionContractData(to: toAddress, value: amountValue)

            return ethereumKit.estimateGas(contractAddress: contractAddress, amount: nil, gasLimit: gasLimit, data: data)
        } catch {
            return Single.error(ValidationError.invalidAddress)
        }
    }

}

extension Erc20Kit: ITransactionManagerDelegate {

    func onSyncSuccess(transactions: [Transaction]) {
        state.syncState = .synced

        guard !transactions.isEmpty else {
            return
        }

        state.transactionsSubject.onNext(transactions.map { TransactionInfo(transaction: $0) })
    }

    func onSyncTransactionsError() {
        state.syncState = .notSynced
    }

}

extension Erc20Kit: IBalanceManagerDelegate {

    func onSyncBalanceSuccess(balance: BigUInt) {
        state.balance = balance

        transactionManager.sync()
    }

    func onSyncBalanceError() {
        state.syncState = .notSynced
    }

}

extension Erc20Kit {

    public static func instance(ethereumKit: EthereumKit, contractAddress: String) throws -> Erc20Kit {
        let databaseFileName = "\(ethereumKit.uniqueId)-\(contractAddress)"

        guard let contractAddress = Data(hex: contractAddress) else {
            throw TokenError.invalidAddress
        }

        let address = ethereumKit.address

        let storage: ITransactionStorage & ITokenBalanceStorage = try GrdbStorage(databaseDirectoryUrl: databaseDirectoryUrl(), databaseFileName: databaseFileName)

        let dataProvider: IDataProvider = DataProvider(ethereumKit: ethereumKit)
        let transactionBuilder: ITransactionBuilder = TransactionBuilder()
        var transactionManager: ITransactionManager = TransactionManager(contractAddress: contractAddress, address: address, storage: storage, dataProvider: dataProvider, transactionBuilder: transactionBuilder)
        var balanceManager: IBalanceManager = BalanceManager(contractAddress: contractAddress, address: address, storage: storage, dataProvider: dataProvider)

        let erc20Kit = Erc20Kit(ethereumKit: ethereumKit, transactionManager: transactionManager, balanceManager: balanceManager)

        transactionManager.delegate = erc20Kit
        balanceManager.delegate = erc20Kit

        return erc20Kit
    }

    public static func clear(exceptFor excludedFiles: [String]) throws {
        let fileManager = FileManager.default
        let fileUrls = try fileManager.contentsOfDirectory(at: databaseDirectoryUrl(), includingPropertiesForKeys: nil)

        for filename in fileUrls {
            if !excludedFiles.contains(where: { filename.lastPathComponent.contains($0) }) {
                try fileManager.removeItem(at: filename)
            }
        }
    }

    private static func databaseDirectoryUrl() throws -> URL {
        let fileManager = FileManager.default

        let url = try fileManager
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("erc20-kit", isDirectory: true)

        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)

        return url
    }

}

extension Erc20Kit {

    public enum TokenError: Error {
        case invalidAddress
        case notRegistered
        case alreadyRegistered
    }

    public enum ValidationError: Error {
        case invalidAddress
        case invalidContractAddress
        case invalidValue
    }

    public enum SyncState {
        case notSynced
        case syncing
        case synced
    }

}
