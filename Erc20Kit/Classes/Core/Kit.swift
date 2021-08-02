import RxSwift
import EthereumKit
import BigInt

public class Kit {
    private let disposeBag = DisposeBag()

    private let contractAddress: Address
    private let ethereumKit: EthereumKit.Kit
    private let transactionManager: ITransactionManager
    private let balanceManager: IBalanceManager
    private let allowanceManager: AllowanceManager

    private let state: KitState

    init(contractAddress: Address, ethereumKit: EthereumKit.Kit, transactionManager: ITransactionManager, balanceManager: IBalanceManager, allowanceManager: AllowanceManager, state: KitState = KitState()) {
        self.contractAddress = contractAddress
        self.ethereumKit = ethereumKit
        self.transactionManager = transactionManager
        self.balanceManager = balanceManager
        self.allowanceManager = allowanceManager
        self.state = state

        onUpdateSyncState(syncState: ethereumKit.syncState)
        state.balance = balanceManager.balance

        ethereumKit.syncStateObservable
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] in
                    self?.onUpdateSyncState(syncState: $0)
                })
                .disposed(by: disposeBag)

        transactionManager.transactionsObservable
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] _ in
                    self?.balanceManager.sync()
                })
                .disposed(by: disposeBag)
    }

    private func onUpdateSyncState(syncState: EthereumKit.SyncState) {
        switch syncState {
        case .synced:
            state.syncState = .syncing(progress: nil)
            balanceManager.sync()
        case .syncing:
            state.syncState = .syncing(progress: nil)
        case .notSynced(let error):
            state.syncState = .notSynced(error: error)
        }
    }

}

extension Kit {

    public func start() {
        if case .synced = ethereumKit.syncState {
            balanceManager.sync()
        }
    }

    public func stop() {
    }

    public func refresh() {
    }

    public var syncState: SyncState {
        state.syncState
    }

    public var transactionsSyncState: SyncState {
        ethereumKit.transactionsSyncState
    }

    public var balance: BigUInt? {
        state.balance
    }

    public func transactionsSingle(from hash: Data?, limit: Int?) throws -> Single<[FullTransaction]> {
        transactionManager.transactionsSingle(from: hash, limit: limit)
    }

    public func pendingTransactions() -> [FullTransaction] {
        transactionManager.pendingTransactions()
    }

    public var syncStateObservable: Observable<SyncState> {
        state.syncStateSubject.asObservable()
    }

    public var transactionsSyncStateObservable: Observable<SyncState> {
        ethereumKit.transactionsSyncStateObservable
    }

    public var balanceObservable: Observable<BigUInt> {
        state.balanceSubject.asObservable()
    }

    public var transactionsObservable: Observable<[FullTransaction]> {
        transactionManager.transactionsObservable
    }

    public func allowanceSingle(spenderAddress: Address, defaultBlockParameter: DefaultBlockParameter = .latest) -> Single<String> {
        allowanceManager.allowanceSingle(spenderAddress: spenderAddress, defaultBlockParameter: defaultBlockParameter)
                .map { amount in
                    amount.description
                }
    }

    public func approveTransactionData(spenderAddress: Address, amount: BigUInt) -> TransactionData {
        allowanceManager.approveTransactionData(spenderAddress: spenderAddress, amount: amount)
    }

    public func transferTransactionData(to: Address, value: BigUInt) -> TransactionData {
        transactionManager.transferTransactionData(to: to, value: value)
    }

}

extension Kit: IBalanceManagerDelegate {

    func onSyncBalanceSuccess(balance: BigUInt) {
        state.syncState = .synced
        state.balance = balance
    }

    func onSyncBalanceFailed(error: Error) {
        state.syncState = .notSynced(error: error)
    }

}

extension Kit {

    public static func instance(ethereumKit: EthereumKit.Kit, contractAddress: Address) throws -> Kit {
        let address = ethereumKit.address

        let dataProvider: IDataProvider = DataProvider(ethereumKit: ethereumKit)
        let transactionManager = TransactionManager(ethereumKit: ethereumKit, contractAddress: contractAddress, contractMethodFactories: Eip20ContractMethodFactories.shared)
        let balanceManager = BalanceManager(ethereumKit: ethereumKit, contractAddress: contractAddress, address: address, dataProvider: dataProvider)
        let allowanceManager = AllowanceManager(ethereumKit: ethereumKit, contractAddress: contractAddress, address: address)

        let erc20Kit = Kit(contractAddress: contractAddress, ethereumKit: ethereumKit, transactionManager: transactionManager, balanceManager: balanceManager, allowanceManager: allowanceManager)

        balanceManager.delegate = erc20Kit

        return erc20Kit
    }

    public static func addTransactionSyncer(to evmKit: EthereumKit.Kit) {
        evmKit.add(transactionSyncer: Erc20TransactionSyncer(provider: evmKit.etherscanService))
    }

    public static func addDecorator(to evmKit: EthereumKit.Kit) {
        evmKit.add(decorator: Eip20TransactionDecorator(userAddress: evmKit.address, contractMethodFactories: Eip20ContractMethodFactories.shared))
    }

}
