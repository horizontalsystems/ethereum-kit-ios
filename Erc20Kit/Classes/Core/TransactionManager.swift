import EthereumKit
import BigInt
import RxSwift

class TransactionManager {
    private let disposeBag = DisposeBag()

    private let contractAddress: Address
    private let ethereumKit: EthereumKit.Kit
    private let contractMethodFactories: Eip20ContractMethodFactories
    private var storage: ITransactionStorage
    private let address: Address
    private let tags: [[String]]

    private let transactionsSubject = PublishSubject<[FullTransaction]>()

    var transactionsObservable: Observable<[FullTransaction]> {
        transactionsSubject.asObservable()
    }

    init(contractAddress: Address, ethereumKit: EthereumKit.Kit, contractMethodFactories: Eip20ContractMethodFactories, storage: ITransactionStorage) {
        self.contractAddress = contractAddress
        self.ethereumKit = ethereumKit
        self.contractMethodFactories = contractMethodFactories
        self.storage = storage

        address = ethereumKit.receiveAddress
        tags = [[contractAddress.hex], ["eip20Transfer", "eip20Approve"]]

        ethereumKit.allTransactionsObservable
                .subscribe { [weak self] in
                    self?.processTransactions(fullTransactions: $0)
                }
                .disposed(by: disposeBag)
    }

    private func processTransactions(fullTransactions: [FullTransaction]) {
        let erc20Transactions = fullTransactions.filter { fullTransaction in
            let transaction = fullTransaction.transaction

            if let decoration = fullTransaction.mainDecoration {
                switch decoration {
                case let transfer as TransferTransactionDecoration:
                    return transfer.to == address || transaction.from == address

                case is ApproveTransactionDecoration: return transaction.from == address

                default: return false
                }
            }

            for decoration in fullTransaction.eventDecorations {
                switch decoration {
                case let transfer as TransferEventDecoration:
                    return transfer.from == address || transfer.to == address

                case let approve as ApproveEventDecoration:
                    return approve.owner == address

                default: return false
                }
            }

            return false
        }

        if !erc20Transactions.isEmpty {
            transactionsSubject.onNext(erc20Transactions)
        }

        if let lastSyncOrder = fullTransactions.sorted(by: { a, b in a.transaction.syncOrder > b.transaction.syncOrder }).first {
            storage.lastSyncOrder = lastSyncOrder.transaction.syncOrder
        }
    }

}

extension TransactionManager: ITransactionManager {

    func transactionsSingle(from hash: Data?, limit: Int?) -> Single<[FullTransaction]> {
        ethereumKit.transactionsSingle(tags: tags, fromHash: hash, limit: limit)
    }

    func pendingTransactions() -> [FullTransaction] {
        ethereumKit.pendingTransactions(tags: tags)
    }

    func transferTransactionData(to: Address, value: BigUInt) -> TransactionData {
        TransactionData(
                to: contractAddress,
                value: BigUInt.zero,
                input: TransferMethod(to: to, value: value).encodedABI()
        )
    }

    func sync() {
        let fullTransactions = ethereumKit.fullTransactions(fromSyncOrder: storage.lastSyncOrder)

        processTransactions(fullTransactions: fullTransactions)
    }

}
