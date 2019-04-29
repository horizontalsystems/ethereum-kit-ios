import RxSwift
import EthereumKit
import HSCryptoKit
import BigInt

public class Erc20Kit {
    private let gasLimit = 100_000

    private let disposeBag = DisposeBag()

    private let ethereumKit: EthereumKit
    private let transactionManager: ITransactionManager
    private let balanceManager: IBalanceManager

    private let state: KitState

    init(ethereumKit: EthereumKit, transactionManager: ITransactionManager, balanceManager: IBalanceManager, state: KitState = KitState()) {
        self.ethereumKit = ethereumKit
        self.transactionManager = transactionManager
        self.balanceManager = balanceManager
        self.state = state

        onUpdateSyncState(syncState: ethereumKit.syncState)
        state.balance = balanceManager.balance

        ethereumKit.syncStateObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
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
            transactionManager.sync()
        }
    }

}

extension Erc20Kit {

    public var syncState: SyncState {
        return state.syncState
    }

    public var balance: String? {
        return state.balance?.description
    }

    public func fee(gasPrice: Int) -> Decimal {
        return Decimal(gasPrice) * Decimal(gasLimit)
    }

    public func sendSingle(to: String, value: String, gasPrice: Int) throws -> Single<TransactionInfo> {
        let to = try convert(address: to)

        guard let value = BigUInt(value) else {
            throw SendError.invalidValue
        }

        return transactionManager.sendSingle(to: to, value: value, gasPrice: gasPrice, gasLimit: gasLimit)
                .map({ TransactionInfo(transaction: $0) })
                .do(onSuccess: { [weak self] transaction in
                    self?.state.transactionsSubject.onNext([transaction])
                })
    }

    public func transactionsSingle(from: (hash: String, index: Int)?, limit: Int?) throws -> Single<[TransactionInfo]> {
        let from = try from.map {
            (hash: try convert(address: $0.hash), index: $0.index)
        }

        return transactionManager.transactionsSingle(from: from, limit: limit)
                .map { transactions in
                    transactions.map {
                        TransactionInfo(transaction: $0)
                    }
                }
    }

    public var syncStateObservable: Observable<SyncState> {
        return state.syncStateSubject.asObservable()
    }

    public var balanceObservable: Observable<String> {
        return state.balanceSubject.asObservable()
    }

    public var transactionsObservable: Observable<[TransactionInfo]> {
        return state.transactionsSubject.asObservable()
    }

    public func clear() {
        transactionManager.clear()
        balanceManager.clear()
    }

}

extension Erc20Kit: ITransactionManagerDelegate {

    func onSyncSuccess(transactions: [Transaction]) {
        guard !transactions.isEmpty else {
            state.syncState = .synced
            return
        }

        state.transactionsSubject.onNext(transactions.map { TransactionInfo(transaction: $0) })
        balanceManager.sync()
    }

    func onSyncTransactionsError() {
        state.syncState = .notSynced
    }

}

extension Erc20Kit: IBalanceManagerDelegate {

    func onSyncBalanceSuccess(balance: BigUInt) {
        state.balance = balance
        state.syncState = .synced
    }

    func onSyncBalanceError() {
        state.syncState = .notSynced
    }

}

extension Erc20Kit {

    public static func instance(ethereumKit: EthereumKit, contractAddress: String) throws -> Erc20Kit {
        let databaseFileName = "erc20_\(contractAddress)"

        guard let contractAddress = Data(hex: contractAddress) else {
            throw TokenError.invalidAddress
        }

        let address = ethereumKit.receiveAddressData

        let storage: ITransactionStorage & ITokenBalanceStorage = GrdbStorage(databaseFileName: databaseFileName)

        let dataProvider: IDataProvider = DataProvider(ethereumKit: ethereumKit)
        let transactionBuilder: ITransactionBuilder = TransactionBuilder()
        var transactionManager: ITransactionManager = TransactionManager(contractAddress: contractAddress, address: address, storage: storage, dataProvider: dataProvider, transactionBuilder: transactionBuilder)
        var balanceManager: IBalanceManager = BalanceManager(contractAddress: contractAddress, address: address, storage: storage, dataProvider: dataProvider)

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

    public enum SyncState {
        case notSynced
        case syncing
        case synced
    }

}
