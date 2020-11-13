import RxSwift
import BigInt
import EthereumKit

class TransactionManager {
    private let scheduler = ConcurrentDispatchQueueScheduler(queue: DispatchQueue(label: "transactionManager.erc20_transactions", qos: .background))
    private let disposeBag = DisposeBag()

    weak var delegate: ITransactionManagerDelegate?

    private let contractAddress: Address
    private let address: Address
    private let storage: ITransactionStorage
    private let transactionProvider: ITransactionProvider
    private let dataProvider: IDataProvider
    private let transactionBuilder: ITransactionBuilder

    private var delayTime = 3
    private let delayTimeIncreaseFactor = 2
    private var retryCount = 0
    private var syncing: Bool = false

    init(contractAddress: Address, address: Address, storage: ITransactionStorage, transactionProvider: ITransactionProvider, dataProvider: IDataProvider, transactionBuilder: ITransactionBuilder) {
        self.contractAddress = contractAddress
        self.address = address
        self.storage = storage
        self.transactionProvider = transactionProvider
        self.dataProvider = dataProvider
        self.transactionBuilder = transactionBuilder
    }

    private func withFailedTransactions(transactions: [Transaction]) -> Single<[Transaction]> {
        var pendingTransactions = storage.pendingTransactions

        for transaction in transactions {
            if let txIndex = pendingTransactions.firstIndex(where: { $0.transactionHash == transaction.transactionHash && $0.from == transaction.from && $0.to == transaction.to }) {
                pendingTransactions.remove(at: txIndex)

                // when this transaction was sent interTransactionIndex was set to 0, so we need it to set 0 for it to replace the transaction in database
                transaction.interTransactionIndex = 0
            }
        }

        guard !pendingTransactions.isEmpty else {
            return Single.just(transactions)
        }

        return dataProvider.getTransactionStatuses(transactionHashes: pendingTransactions.map { $0.transactionHash })
                .observeOn(scheduler)
                .map { [weak self] statuses -> [Transaction] in
                    transactions + (self?.failedTransactions(pendingTransactions: pendingTransactions, statuses: statuses) ?? [])
                }
                .catchErrorJustReturn(transactions)
    }

    private func finishSync(transactions: [Transaction]) {
        if transactions.isEmpty && retryCount > 0 {
            retryCount -= 1
            delayTime = delayTime * delayTimeIncreaseFactor
            sync(delayTime: delayTime)
            return
        }
        
        syncing = false
        retryCount = 0
        storage.save(transactions: transactions)
        delegate?.onSyncSuccess(transactions: transactions)
    }

    func finishSync(error: Error) {
        syncing = false
        retryCount = 0
        delegate?.onSyncTransactionsFailed(error: error)
    }

    private func failedTransactions(pendingTransactions: [Transaction], statuses: [(Data, TransactionStatus)]) -> [Transaction] {
        statuses.compactMap { (hash, status) -> Transaction? in
            if status == .failed, let txIndex = pendingTransactions.firstIndex(where: { $0.transactionHash == hash }) {
                pendingTransactions[txIndex].isError = true
                return pendingTransactions[txIndex]
            }
            return nil
        }
    }

    private func sync(delayTime: Int? = nil) {
        let lastBlockHeight = dataProvider.lastBlockHeight
        let lastTransactionBlockHeight = storage.lastTransactionBlockHeight ?? 0

        var single = transactionProvider
                .transactions(contractAddress: contractAddress, address: address, from: lastTransactionBlockHeight + 1, to: lastBlockHeight)
                .subscribeOn(scheduler)
                .flatMap { [weak self] transactions -> Single<[Transaction]> in
                    self?.withFailedTransactions(transactions: transactions.filter { $0.value != 0 }) ?? Single.just(transactions)
                }

        if let delayTime = delayTime {
            single = single.delaySubscription(DispatchTimeInterval.seconds(delayTime), scheduler: scheduler)
        }

        single.subscribe(onSuccess: { [weak self] transactions in
                    self?.finishSync(transactions: transactions)
                }, onError: { [weak self] error in
                    self?.finishSync(error: error)
                })
                .disposed(by: disposeBag)
    }

}

extension TransactionManager: ITransactionManager {

    func transactionsSingle(from: (hash: Data, interTransactionIndex: Int)?, limit: Int?) -> Single<[Transaction]> {
        storage.transactionsSingle(from: from, limit: limit)
    }

    func pendingTransactions() -> [Transaction] {
        storage.pendingTransactions
    }

    func transaction(hash: Data, interTransactionIndex: Int) -> Transaction? {
        storage.transaction(hash: hash, interTransactionIndex: interTransactionIndex)
    }

    func transactionContractData(to: Address, value: BigUInt) -> Data {
        transactionBuilder.transferTransactionInput(to: to, value: value)
    }

    func sendSingle(to: Address, value: BigUInt, gasPrice: Int, gasLimit: Int) -> Single<Transaction> {
        let transactionInput = transactionBuilder.transferTransactionInput(to: to, value: value)

        return dataProvider.sendSingle(contractAddress: contractAddress, transactionInput: transactionInput, gasPrice: gasPrice, gasLimit: gasLimit)
                .map { [unowned self] hash in
                    Transaction(transactionHash: hash, from: self.address, to: to, value: value)
                }
                .do(onSuccess: { [weak self] transaction in
                    self?.storage.save(transactions: [transaction])
                })
    }

    func immediateSync() {
        guard !syncing else {
            return
        }

        syncing = true
        delegate?.onSyncStarted()

        sync()
    }

    func delayedSync(expectTransaction: Bool) {
        guard !syncing else {
            return
        }

        retryCount = expectTransaction ? 5 : 3
        delayTime = 3

        syncing = true
        delegate?.onSyncStarted()

        sync(delayTime: delayTime)
    }
}
